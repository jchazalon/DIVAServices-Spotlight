###
Controller AlgorithmsPageController

* displays information about all available algorithms
* handles socket.io messages if any algorithms have changed
###
do ->
  'use strict'

  AlgorithmsPageController = ($scope, $state, socketPrepService, algorithmsPrepService, diaSocket, toastr) ->
    vm = @
    vm.algorithms = algorithmsPrepService.algorithms

    console.log 'algorithms: ' + JSON.stringify(vm.algorithms)
    vm.tableOptions =
      data: vm.algorithms
      columns: [
        {
          data: 'name'
          render: (data, type, row) ->
            if type is 'display'
              '<span class="text-capitalize algorithm-name">' + data + '</span>'
            else
              data
        }
        {
          data : 'type'
          render: (data, type, row) ->
            data ||= 'general'
        }
        { data: 'description' }
        {
          data: '_id'
          width: '1%'
          render: (data, type, row) ->
            if type is 'display'
              '<button class="btn btn-xs btn-primary hvr-grow-shadow action-button-apply">Apply <i class="fa fa-arrow-right"</button>'
            else
              data
        }
      ]
      order: [[3, 'desc']]
      pageLength: 20
      lengthMenu: [ [10, 20, 50, -1], [10, 20, 50, 'All'] ]
      drawCallback: ->
        table = @
        table.on 'click', '.action-button-apply', ->
          entry = table.api().row($(this).parents('tr')).data() or table.api().row($(this).parents('tr').prev()).data()
          $state.go 'algorithm', id: entry._id
        table.on 'click', '.algorithm-name', ->
          entry = table.api().row($(this).parents('tr')).data() or table.api().row($(this).parents('thr').prev()).data()
          $state.go 'algorithm', id: entry._id

    if socketPrepService.settings.run
      $scope.$on 'socket:update algorithms', (ev, algorithms) ->
        table = $('#algorithm-table').DataTable()
        angular.forEach algorithms, (algorithm) ->
          angular.forEach vm.algorithms, (scopeAlgorithm, index) ->
            if algorithm._id is scopeAlgorithm._id
              vm.algorithms[index] = algorithm
              table.rows (idx, data) ->
                if data._id is algorithm._id
                  table.row(idx).data(algorithm).draw()
        toastr.info 'Algorithms have changed', 'Updated'

      $scope.$on 'socket:add algorithms', (ev, algorithms) ->
        table = $('#algorithm-table').DataTable()
        angular.forEach algorithms, (algorithm) ->
          vm.algorithms.push algorithm
          table.row.add(algorithm).draw()
        toastr.info 'Added new algorithms', 'Added'

      $scope.$on 'socket:delete algorithms', (ev, algorithms) ->
        table = $('#algorithm-table').DataTable()
        angular.forEach algorithms, (algorithm) ->
          angular.forEach vm.algorithms, (scopeAlgorithm, index) ->
            if algorithm._id is scopeAlgorithm._id
              vm.algorithms.splice index, 1
              table.rows((idx, data) ->
                data._id is algorithm._id
              ).remove().draw()
        toastr.info 'Deleted one or more algorithms', 'Delete'

      $scope.$on 'socket:error', (ev, data) ->
        toastr.error 'There was an error while fetching algorithms', 'Error'
    vm

  angular.module('app.algorithms')
    .controller 'AlgorithmsPageController', AlgorithmsPageController

  AlgorithmsPageController.$inject = [
    '$scope'
    '$state'
    'socketPrepService'
    'algorithmsPrepService'
    'diaSocket'
    'toastr'
  ]
