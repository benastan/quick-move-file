{$, View, EditorView} = require 'atom'
fs = null
path = null
currentCommand = null
quickMoveFileView = null

mkdirp = (pathToFile) ->
  directoryPath = path.dirname(pathToFile)
  fs.makeTreeSync(directoryPath) unless fs.existsSync(directoryPath)

setup: (createView = true) ->
  fs ?= require 'fs-plus'
  path ?= require 'path'
  quickMoveFileView = new QuickMoveFileView() if createView

updateRepo = (fn) ->
  if repo = atom.project.getRepo()
    fn(repo)

deletePath = (pathToDelete) ->
  fs.removeSync(pathToDelete) if fs.existsSync(pathToDelete)
  updateRepo (repo) -> repo.getPathStatus(pathToDelete)

commands =
  quickMoveFile: =>
    setup()
    currentCommand = 'quickMoveFile'
    quickMoveFileView.hint.text('Enter the new path for the file')
    quickMoveFileView.attach()

  quickDuplicateFile: =>
    setup()
    currentCommand = 'quickDuplicateFile'
    quickMoveFileView.hint.text('Enter the new path for the duplicate file')
    quickMoveFileView.attach()

  quickOpenFile: =>
    setup()
    currentCommand = 'quickOpenFile'
    quickMoveFileView.hint.text('Enter the path of the file to open')
    quickMoveFileView.attach()

  quickDeleteCurrentFile: =>
    setup(false)
    editor = atom.workspace.getActiveEditor()
    deletePath(editor.buffer.file.path)
    atom.workspaceView.destroyActivePaneItem()

  quickDeleteFile: =>
    setup()
    currentCommand = 'quickDeleteFile'
    quickMoveFileView.hint.text('Enter the path of the file to open')
    quickMoveFileView.attach()

commandMap = [
  [ "quick-move-file", 'quickMoveFile' ]
  [ "quick-duplicate-file", 'quickDuplicateFile' ]
  [ "quick-open-file", 'quickOpenFile' ]
  [ "quick-delete-current-file", 'quickDeleteCurrentFile' ]
  [ "quick-delete-file", 'quickDeleteFile' ]
]

module.exports =
class QuickMoveFileView extends View
  @configDefaults:
    quickMoveFile: true
    quickDuplicateFile: true
    quickOpenFile: true
    quickDeleteCurrentFile: true
    quickDeleteFile: true

  @content: () ->
    @div class: 'quick-move-file overlay from-top', =>
      @label class: 'icon', outlet: 'hint'
      @subview 'miniEditor', new EditorView(mini: true)

  @activate: () ->
    for [command, configKey] in commandMap
      unless atom.config.settings['quick-move-file'][configKey] is false
        atom.workspaceView.command "quick-move-file:#{command}", commands[configKey]

  @deactivate: () ->
    quickMoveFileView.detach() if quickMoveFileView?

  initialize: () ->
    @on 'core:confirm', => @[currentCommand]()
    @on 'core:cancel', => @cancel()
    @miniEditor.hiddenInput.on 'focusout', => @remove()

  quickOpenFile: () ->
    openPath = @miniEditor.getText()
    atom.workspace.open(openPath)
    @close()

  quickMoveFile: () ->
    newPath = @miniEditor.getText()
    return if newPath is @originalPath
    mkdirp(newPath)
    fs.moveSync(@originalPath, newPath)
    updateRepo (repo) ->
      repo.getPathStatus(@originalPath)
      repo.getPathStatus(newPath)
    @close()

  quickDeleteFile: () ->
    deletePath(@miniEditor.getText())
    @close()

  quickDuplicateFile: () ->
    pathForDuplicate = @miniEditor.getText()
    return if pathForDuplicate is @originalPath
    mkdirp(pathForDuplicate)
    content = fs.readFileSync(@originalPath)
    fs.writeFileSync(pathForDuplicate, content)
    updateRepo (repo) -> repo.getPathStatus(pathForDuplicate)
    @close()

  attach: () ->
    @originalPath = atom.workspace.getActiveEditor().buffer.file.path
    @miniEditor.setText(@originalPath)
    atom.workspaceView.append(this)
    @miniEditor.focus()
    @miniEditor.scrollToCursorPosition()

  close: () ->
    @remove()
    atom.workspaceView.focus()

  cancel: () ->
    @remove()
