# beast-smc
Development of infrastructure to implement SMC for BEAST.

This is work-in-progress to create a hybrid SMC+MCMC sampler that can update an existing BEAST MCMC chain with new data as they become available.

## The tiny dataset example

A tiny dataset located in the `examples/tiny` directory can be used to run the
code. That directory contains two files. The first, `online.xml` is a BEAST xml
containing a set of 5 taxa (these are taken from benchmark1.xml in the beast-mcmc
package). The second is `online_newtaxa.xml` which is identical to the first
file except that 5 new taxa have been added to the alignment. Note that the
alignment of the original 5 taxa remains unchanged -- no new alignment columns
are added.

We would like to have an initial MCMC run of the first five taxa, and then add
the new five to that run using SMC. To do so, we first use MCMC to take samples
from the posterior for the first five:

```
java -jar ../beast-mcmc/build/dist/beast.jar -dump_every 150 -overwrite examples/tiny/online.xml
```
Note that the path to beast.jar may need to be adjusted. This command will
produce a large number of `beast_state*` files. Future revisions may do something
cleaner with this, but currently we must create a new directory for these and
move them into it:

```
mkdir checkpoints
mv beast_state* checkpoints
```

Those checkpoints will be used to initialize the SMC particle system. We are
now ready to run SMC to add the new sequences:

```
bin/beast_smc --checkpoint_dir checkpoints/ --original_xml examples/tiny/online.xml --new_xml examples/tiny/online_newtaxa.xml --beast ../beast-mcmc/build/dist/beast.jar --output smc --particles 10
```

This will create a directory tree under the specified output location `smc`.
The directory tree contains a subdirectory for each SMC iteration that adds one new
sequence to the posterior. Each iteration's subdirectory contains a directory
for each SMC particle. The MCMC logs from each particle at the final iteration
can be combined and summarised to yield a complete posterior approximation.
