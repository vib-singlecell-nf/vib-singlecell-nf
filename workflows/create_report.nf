//
// Version: 
// Test: 
// Command: 
//
/*
 * QC workflow 
 * Source:
 * 
 * Steps considered: 
 * - filter (cell, gene) + qc report
 */ 

nextflow.preview.dsl=2

//////////////////////////////////////////////////////
//  process imports:

include '../processes/reports.nf' params(params)

//////////////////////////////////////////////////////
//  Define the workflow 

workflow GENERATE_DUAL_INPUT_REPORT {

    take:
        data1  // anndata
        data2 // anndata
        ipynb
        reportTitle

    main:
        report_notebook = SC__SCANPY__GENERATE_DUAL_INPUT_REPORT(
            ipynb,
            data1.join(data2),
            reportTitle
        )
        SC__SCANPY__REPORT_TO_HTML(report_notebook)

    emit:
        report_notebook

}

workflow GENERATE_REPORT {

    take:
        pipelineStep
        data // anndata
        ipynb
        isMultiArgsMode

    main:
        def reportTitle = "SC_Scanpy_" + pipelineStep.toLowerCase() + "_report"
        if(isMultiArgsMode) {
            switch(pipelineStep) {
                case "CLUSTERING":
                    report_notebook = SC__SCANPY__MULTI_CLUSTERING_GENERATE_REPORT(
                        ipynb,
                        // expects (sample_id, adata, ...arguments)
                        data,
                        reportTitle
                    )
                    break;
                default: 
                    throw new Exception("Invalid pipeline step")
                    break; 
            }
        } else {
            report_notebook = SC__SCANPY__GENERATE_REPORT(
                ipynb,
                // expects (sample_id, adata)
                data,
                reportTitle
            )
        }
        SC__SCANPY__REPORT_TO_HTML(report_notebook)

    emit:
        report_notebook

}
