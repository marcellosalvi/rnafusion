include { KALLISTO_QUANT    }     from '../../modules/local/kallisto/quant/main'
include { PIZZLY            }     from '../../modules/local/pizzly/detect/main'

workflow PIZZLY_WORKFLOW {
    take:
        reads
        ch_gtf
        ch_transcript

    main:
        ch_versions = Channel.empty()
        ch_dummy_file = file("$baseDir/assets/dummy_file_pizzly.txt", checkIfExists: true)

        if ((params.pizzly || params.all) && !params.fusioninspector_only) {
            if (params.pizzly_fusions) {
                ch_pizzly_fusions = reads.combine(Channel.value(file(params.pizzly_fusions, checkIfExists:true)))
                                    .map { meta, reads, fusions -> [ meta, fusions ] }
            } else {
                KALLISTO_QUANT(reads, params.pizzly_ref )
                ch_versions = ch_versions.mix(KALLISTO_QUANT.out.versions)

                PIZZLY( KALLISTO_QUANT.out.txt, ch_transcript, ch_gtf )
                ch_versions = ch_versions.mix(PIZZLY.out.versions)

                ch_pizzly_fusions = PIZZLY.out.fusions
            }
        }
        else  {
            ch_pizzly_fusions = reads.combine(Channel.value(file(ch_dummy_file, checkIfExists:true)))
                                            .map { meta, reads, fusions -> [ meta, fusions ] }
        }

    emit:
        fusions             = ch_pizzly_fusions
        versions            = ch_versions.ifEmpty(null)
    }

