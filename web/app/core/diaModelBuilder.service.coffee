do ->
  'use strict'

  diaModelBuilder = ->

    factory = ->
      prepareAlgorithmInputModel: prepareAlgorithmInputModel
      prepareAlgorithmSendModel: prepareAlgorithmSendModel
      prepareResultForDatatable: prepareResultForDatatable

    # prepare algorithm from backend to be displayed on algorithm page
    #
    # highlighter: <rectangle, polygon, circle, null>
    # inputs: algorithms input (as defined in schemas.json)
    # model: prepare input data for dynamic form
    # algorithm: copy over all default settings
    prepareAlgorithmInputModel = (id, algorithm) ->
      data =
        highlighter: null
        inputs: []
        model: {}
        algorithm: algorithm
        infos: []

      data.algorithm.id = id

      if algorithm.description? then data.infos.push description: algorithm.description
      angular.forEach algorithm.info, (value, key) ->
        obj = {}
        if key is 'expectedRuntime' and not isNaN(parseFloat(value))
          runtime = parseFloat value
          if runtime is 1 then runtime += ' second' else runtime += ' seconds'
          obj[key] = runtime
        else
          obj[key] = value
        data.infos.push obj

      # prepare input information
      angular.forEach algorithm.input, (entry) ->
        key = Object.keys(entry)[0]
        if key is 'highlighter'
          # setup highlighter if there is one
          data.highlighter = entry.highlighter
        else
          # setup inputs
          data.inputs.push entry
          switch key
            when 'select'
              data.model[entry[key].name] = entry[key].options.values[entry[key].options.default]
            else
              data.model[entry[key].name] = entry[key].options.default or null

      data: data

    # prepare algorithm information to be send to backend
    #
    # algorithm: just copy over algorithm information
    # image: path to the selected image
    # inputs: model submitted by dynamic form
    # highlighter: path information of paperJS highlighter (if any)
    prepareAlgorithmSendModel = (algorithm, selectedImage, model, highlighterData) ->
      item =
        algorithm: algorithm
        image: selectedImage
        inputs: model
        highlighter: {}

      if highlighterData?.path?.view?
        path = highlighterData.path.clone()
        path.visible = false
        path.fullySelected = false
        path.scale highlighterData.scale, [0, 0]
        type = highlighterData.type

        if type is 'circle'
          item.highlighter =
            type: type
            closed: path.closed
            position: [parseInt(path.position.x), parseInt(path.position.y)]
            radius: path.bounds.width / 2
        else
          item.highlighter =
            type: type
            closed: path.closed
            segments: []
          angular.forEach path.segments, (segment) ->
            x = parseInt segment.point.x
            y = parseInt segment.point.y
            @.push [x, y]
          , item.highlighter.segments

      item: item

    # prepare algorithm input and output data to be displayed in datatable under results page
    prepareResultForDatatable = (input, output) ->
      result =
        algorithm:
          id: input.algorithm.id
          uuid: input.uuid
          name: input.algorithm.name
          description: input.algorithm.description
        submit:
          start: input.start
          end: input.end
          duration: input.duration
        input:
          uuid: input.uuid
          inputs: input.inputs
          highlighter: input.highlighter
          image: input.image
        output: output

      result.output.uuid = input.uuid

      if angular.equals {}, result.input.inputs then result.input.inputs = null
      if angular.equals {}, result.output.output then result.output.output = null
      if angular.equals {}, result.input.highlighter
        result.input.highlighter = null
      else
        parsedHighlighter = {}
        parsedHighlighter[result.input.highlighter.type] = result.input.highlighter
        result.input.highlighters = [parsedHighlighter]

      result: result

    factory()

  angular.module('app.core')
    .factory 'diaModelBuilder', diaModelBuilder
