#!/usr/bin/env nextflow

params.out_dir = 'out'
params.particles = 10000
params.particles_per_instance = 10

process prep_smc_iter {
   input:
   file(xmlfile) from Channel.fromPath(params.original_xml)

   output:
   file("group*") into particles mode flatten

   """
   beast_smc_modular --mode=prep --checkpoint_dir ${params.ckpnt} --original_xml ${xmlfile} --new_xml ${params.new_xml} --particles ${params.particles} --output . --ppi ${params.particles_per_instance}
   """
}

process update_particles {
  input:
  file(particle_group) from particles

  output:
  file("${particle_group}") into updated

  """
  java -cp \$BEASTJAR dr.app.realtime.CheckPointUpdaterApp  -load_state `cat ${particle_group}/particle_list` -update_choice F84Distance -output_file `cat ${particle_group}/updated_list` -BEAST_XML ${particle_group}/beast.xml
  """
}

all_updated_particles = updated.collect()

process filter_particles {
  input:
  file("*") from all_updated_particles

  output:
  file("result/*") into filtered_particles mode flatten
  file("smc_filter.out") into filter_info
  file("weights-resampled.csv") into filter_weights

  """
  mkdir iteration
  mv group*/*.ckpnt group*/*.part iteration
  mkdir filtered
  beast_smc_modular --mode=filter --particle_dir iteration --particles ${params.particles} --output filtered --new_xml group.0/beast.xml --ppi ${params.particles_per_instance}  --threshold ${params.threshold} --weights ${params.weights} 2> smc_filter.err > smc_filter.out
  mkdir result
  mv filtered/* result
  """
}

filter_info.collectFile(storeDir: params.out_dir)
filter_weights.collectFile(storeDir: params.out_dir)

process run_mcmc {
  input:
  file(group_dir) from filtered_particles

  output:
  file("${group_dir}.updated") into mcmc

  """
  java -cp \$BEASTJAR dr.app.beast.BeastMain -particles ${group_dir} ${group_dir}/beast.xml
  mkdir ${group_dir}.updated
  mv ${group_dir}/*.out ${group_dir}.updated/
  cp ${group_dir}/beast.xml ${group_dir}.updated/
  """
}

all_mcmc_particles = mcmc.collect()

process combine_particles {
  publishDir params.out_dir

  input:
  file(group_dir) from all_mcmc_particles

  output:
  file("all_particles")
  file("beast.xml")

  """
  mkdir all_particles
  mv group.*/*.out all_particles
  cp group.0.updated/beast.xml .
  """
}
