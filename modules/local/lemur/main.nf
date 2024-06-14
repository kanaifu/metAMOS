// NOTE nf-core: If in doubt look at other nf-core/modules to see how we are doing things! :)
//               https://github.com/nf-core/modules/tree/master/modules/nf-core/
//               You can also ask for help via your pull request or on the #modules channel on the nf-core Slack workspace:
//               https://nf-co.re/join
// NOTE nf-core: A module file SHOULD only define input and output files as command-line parameters.
//               All other parameters MUST be provided using the "task.ext" directive, see here:
//               https://www.nextflow.io/docs/latest/process.html#ext
//               where "task.ext" is a string.
//               Any parameters that need to be evaluated in the context of a particular sample
//               e.g. single-end/paired-end data MUST also be defined and evaluated appropriately.
// NOTE nf-core: Optional inputs are not currently supported by Nextflow. However, using an empty
//               list (`[]`) instead of a file can be used to work around this issue.

process LEMUR {
    tag "$meta.id"
    label 'process_high'

    //  NOTE nf-core: For Conda, the build (i.e. "h9402c20_2") must be EXCLUDED to support installation
    //                on different operating systems.
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/lemur:1.0.1--hdfd78af_0':
        'biocontainers/lemur:1.0.1--hdfd78af_0' }"

    input:
    // NOTE nf-core: Where applicable all sample-specific information e.g. "id", "single_end", "read_group"
    //               MUST be provided as an input via a Groovy Map called "meta".
    // NOTE nf-core: Where applicable please provide/convert compressed files as input/output
    //               e.g. "*.fastq.gz" and NOT "*.fastq", "*.bam" and NOT "*.sam" etc.
    tuple val(meta), path(reads), path(database), path(taxonomy)

    output:
    // NOTE nf-core: Named file extensions MUST be emitted for ALL output channels
    tuple val(meta), path("${meta.id}_relative_abundance.tsv"), path("${meta.id}_relative_abundance-*.tsv"), emit: lemur_results
    
    // NOTE nf-core: List additional required output channels/values here    
    path "versions.yml", emit: versions 

    // NOTE: This expression provides control over when the process will be executed.
    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    // NOTE nf-core: Where possible, a command MUST be provided to obtain the version number of the software e.g. 1.10
    //               If the software is unable to output a version number on the command-line then it can be manually specified
    //               e.g. https://github.com/nf-core/modules/blob/master/modules/nf-core/homer/annotatepeaks/main.nf
    //               Each software used MUST provide the software name and version number in the YAML version file (versions.yml)
    // NOTE nf-core: It MUST be possible to pass additional parameters to the tool as a command-line string via the "task.ext.args" directive
    """
    lemur \\
        -i ${reads} \\
        -o "${prefix}_lemur_output" \\
        -d ${database} \\
        --tax-path ${taxonomy} \\
        -r ${task.ext.rank ?: 'species'} \\ 
        -t ${task.cpus} \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        lemur: "$(lemur --version 2>&1 | head -n 1 | awk '{print $2}')"
    END_VERSIONS
    """

    // NOTE: The stub is a lightweight simulation of the tool that mimics output
    //       and is used to speed up testing.
    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def rank = task.ext.rank ?: 'species'

    """
    mkdir -p "${prefix}_lemur_output"
    touch "${prefix}_lemur_output/${prefix}_relative_abundance.tsv"
    touch "${prefix}_lemur_output/${prefix}_relative_abundance-${rank}.tsv"

    # Create dummy probability files (Make sure to adjust these)
    touch "${prefix}_lemur_output/some_probability_file_1_P_rgs_df"
    touch "${prefix}_lemur_output/another_probability_file_2_P_rgs_df"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        lemur: 1.0.1
    END_VERSIONS
    """

}
