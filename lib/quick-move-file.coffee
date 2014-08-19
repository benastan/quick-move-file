{$, View, EditorView} = require 'atom'
fs = require 'fs-plus'
path = require 'path'

module.exports =
class QuickMoveFile extends View
  @content: () ->
    @div class: 'quick-move-file overlay from-top', =>
      @label 'Enter the new path for the file', class: 'icon'
      @subview 'miniEditor', new EditorView(mini: true)

  @activate: () ->
    atom.workspaceView.command "quick-file-move:quick-file-move", =>
      @quickMoveFile = new QuickMoveFile()
      @quickMoveFile.attach()

  @deactivate: () ->
    @quickMoveFile.detach() if @quickMoveFile

  initialize: () ->
    @on 'core:confirm', => @quickMoveFile()
    @on 'core:cancel', => @cancel()
    @miniEditor.hiddenInput.on 'focusout', => @remove()

  quickMoveFile: () ->
    directoryPath = path.dirname(@miniEditor.getText())
    try
      fs.makeTreeSync(directoryPath) unless fs.existsSync(directoryPath)
      fs.moveSync(@originalPath, newPath)
      if repo = atom.project.getRepo()
        repo.getPathStatus(@originalPath)
        repo.getPathStatus(newPath)
      @close()
    catch error

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
