{$, View, EditorView} = require 'atom'
fs = null
path = null
currentCommand = null
quickMoveFileView = null

mkdirp = (pathToFile) ->
  directoryPath = path.dirname(pathToFile)
  fs.makeTreeSync(directoryPath) unless fs.existsSync(directoryPath)

updateRepo = (fn) ->
  if repo = atom.project.getRepo()
    fn(repo)

deletePath = (pathToDelete) ->
  fs.removeSync(pathToDelete) if fs.existsSync(pathToDelete)
  updateRepo (repo) -> repo.getPathStatus(pathToDelete)

module.exports =
class QuickMoveFileView extends View
  @content: () ->
    @div class: 'quick-move-file overlay from-top', =>
      @label class: 'icon', outlet: 'hint'
      @subview 'miniEditor', new EditorView(mini: true)

  @activate: () ->
    atom.workspaceView.command "quick-move-file:quick-move-file", =>
      @setup()
      currentCommand = 'quickMoveFile'
      quickMoveFileView.hint.text('Enter the new path for the file')
      quickMoveFileView.attach()

    atom.workspaceView.command "quick-move-file:quick-duplicate-file", =>
      @setup()
      currentCommand = 'quickDuplicateFile'
      quickMoveFileView.hint.text('Enter the new path for the duplicate file')
      quickMoveFileView.attach()

    atom.workspaceView.command "quick-move-file:quick-open-file", =>
      @setup()
      currentCommand = 'quickOpenFile'
      quickMoveFileView.hint.text('Enter the path of the file to open')
      quickMoveFileView.attach()

    atom.workspaceView.command "quick-move-file:quick-delete-current-file", =>
      @setup(false)
      editor = atom.workspace.getActiveEditor()
      deletePath(editor.buffer.file.path)
      atom.workspaceView.destroyActivePaneItem()

    atom.workspaceView.command "quick-move-file:quick-delete-file", =>
      @setup()
      currentCommand = 'quickDeleteFile'
      quickMoveFileView.hint.text('Enter the path of the file to open')
      quickMoveFileView.attach()

  @setup: (createView = true) ->
    fs ?= require 'fs-plus'
    path ?= require 'path'
    quickMoveFileView = new QuickMoveFileView() if createView

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
