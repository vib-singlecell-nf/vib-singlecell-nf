nextflow.preview.dsl=2

include getBaseName from '../../utils/processes/files.nf'

process SC__SCANPY__DIM_REDUCTION {

  container params.sc.scanpy.container
  publishDir "${params.outdir}/data", mode: 'symlink'

  input:
    file(f)
  output:
    file "${getBaseName(f)}.SC__SCANPY__DIM_REDUCTION_${method}.${params.off}"
  script:
    method = params.dimReductionMethod.replaceAll('-','').toUpperCase()
    """
    ${workflow.projectDir}/src/scanpy/bin/dim_reduction/sc_dim_reduction.py \
         ${(params.containsKey('dimReductionMethod')) ? '--method ' + params.dimReductionMethod : ''} \
         ${(params.containsKey('svdSolver')) ? '--svd-solver ' + params.svdSolver : ''} \
         ${(params.containsKey('nNeighbors')) ? '--n-neighbors ' + params.nNeighbors : ''} \
         ${(params.containsKey('nComps')) ? '--n-comps ' + params.nComps : ''} \
         ${(params.containsKey('nPcs')) ? '--n-pcs ' + params.nPcs : ''} \
         ${(params.containsKey('nJobs')) ? '--n-jobs ' + params.nJobs : ''} \
         $f \
         "${getBaseName(f)}.SC__SCANPY__DIM_REDUCTION_${method}.${params.off}"
    """
}