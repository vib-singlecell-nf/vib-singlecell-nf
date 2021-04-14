nextflow.enable.dsl=2

////////////////////////////////////////////////////////
//  Import sub-workflows/processes from the utils module:
include {
    PUBLISH;
} from '../../utils/workflows/utils.nf' params(params)
include {
    FILE_CONVERTER as FILE_CONVERTER_TO_SCOPE;
} from '../../utils/workflows/fileConverter.nf' params(params)
include {
    UTILS__GENERATE_WORKFLOW_CONFIG_REPORT;
} from '../../utils/processes/reports.nf' params(params)

////////////////////////////////////////////////////////
//  Import sub-workflows/processes from the tool module:
include {
    FILTER;
} from './filter.nf' params(params)
include {
    MERGE;
} from './merge.nf' params(params)
include {
    NORMALIZE;
    NORMALIZE_SCALE_SCT;
} from './normalize.nf' params(params)
include {
    HVG_SELECTION;
} from './hvg_selection.nf' params(params)
include {
    DIM_REDUCTION_PCA;
} from './dim_reduction_pca.nf' params(params)
include {
    DIM_REDUCTION_TSNE_UMAP;
} from './dim_reduction.nf' params(params)
include {
    NEIGHBORHOOD_GRAPH;
} from './neighborhood_graph.nf' params(params)
include {
    CLUSTERING
} from './clustering.nf' params(params)
include {
    DIFFERENTIAL_GENE_EXPRESSION;
} from './deg.nf' params(params)

//////////////////////////////////////////////////////
// Define the workflow

workflow multi_sample {
    take:
        data
    
    main:
        filtered = params.tools.seurat?.filter ? FILTER( data ).filtered : data

        MERGE( 
            filtered.map { it -> it[1] }.toList()
        )
        
        // SCT workflow not supported in multiple sample, since this can have a negative influence on batch effects
        NORMALIZE( MERGE.out ) | HVG_SELECTION
        
        DIM_REDUCTION_PCA( HVG_SELECTION.out.scaled )
        NEIGHBORHOOD_GRAPH( DIM_REDUCTION_PCA.out )
        DIM_REDUCTION_TSNE_UMAP( NEIGHBORHOOD_GRAPH.out )
        CLUSTERING( DIM_REDUCTION_TSNE_UMAP.out.dimred_tsne_umap )
        DIFFERENTIAL_GENE_EXPRESSION( CLUSTERING.out )

        UTILS__GENERATE_WORKFLOW_CONFIG_REPORT(
            file(workflow.projectDir + params.utils.workflow_configuration.report_ipynb)
        )

        PUBLISH(
            CLUSTERING.out,
            params.global.project_name+".multi_sample_seurat.final_output",
            "Rds",
            'seurat',
            false
        )

        FILE_CONVERTER_TO_SCOPE(
            CLUSTERING.out,
            'SINGLE_SAMPLE_SEURAT.final_output',
            'seuratRdsToSCopeLoom',
            null
        )

    emit:
        merged_seurat_rds = MERGE.out
        scope_loom = FILE_CONVERTER_TO_SCOPE.out
        seurat_rds = CLUSTERING.out
        marker_genes = DIFFERENTIAL_GENE_EXPRESSION.out.marker_genes
        marker_genes_xlsx = DIFFERENTIAL_GENE_EXPRESSION.out.marker_genex_xlsx
}