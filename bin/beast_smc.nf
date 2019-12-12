#!/usr/bin/env nextflow

params.out_dir = 'out'
params.particles = 10000
params.particles_per_instance = 10

process prep_smc_iter {
   input:
   file(xmlfile) from Channel.fromPath(params.original_xml)

   output:
   file("group*") into particles mode flatten
   file("group*") into groups  mode flatten

   """
   beast_smc_modular --mode=prep --checkpoint_dir ${params.ckpnt} --original_xml ${xmlfile} --new_xml ${params.new_xml} --particles ${params.particles} --output . --ppi ${params.particles_per_instance} --taxon "${params.taxon}" --state_stem ${params.stem}
   """
}

process update_particles {
  input:
  file(particle_group) from particles

  output:
  file("${particle_group}") into updated

  """
  java -cp \$BEASTJAR dr.app.realtime.CheckPointUpdaterApp  -load_state ${particle_group}/checkpt.zip -update_choice ${params.update_choice} -output_file ${particle_group}/checkpt-updated.zip -BEAST_XML ${particle_group}/beast.xml
  """
}

all_updated_particles = updated.collect()

process filter_particles {
  input:
  file("*") from all_updated_particles

  output:
  file("group*/checkpt-resampled.zip") into filtered_particles mode flatten
  file("smc_filter.out") into filter_info
  file("weights-resampled.csv") into filter_weights
  file("group.0/beast.xml") into beast_xml

  """
  beast_smc_modular --mode=filter --particle_dir . --particles ${params.particles} --output . --new_xml group.0/beast.xml --ppi ${params.particles_per_instance}  --threshold ${params.threshold} --weights ${params.weights} --taxon "${params.taxon}" --state_stem ${params.stem} 2> smc_filter.err > smc_filter.out
  """
}

filter_info.collectFile(storeDir: params.out_dir)
filter_weights.collectFile(storeDir: params.out_dir)
beast_xml.collectFile(storeDir: params.out_dir)

process run_mcmc {
  publishDir params.out_dir

  input:
  file(group) from groups
  file(resampled_zip) from filtered_particles

  output:
  file("${group}/checkpt-resampled.out.zip") into mcmc

  """
  java -cp \$BEASTJAR dr.app.beast.BeastMain -particles ${group}/${resampled_zip} ${group}/beast.xml
  """
}
