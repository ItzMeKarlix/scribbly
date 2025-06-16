import { Editor } from 'https://esm.sh/@tiptap/core@2.0.3'
import StarterKit from 'https://esm.sh/@tiptap/starter-kit@2.0.3'
import Placeholder from 'https://esm.sh/@tiptap/extension-placeholder@2.0.3'

// // Create editor instance (but don't mount yet)
// const editor = new Editor({
//   extensions: [
//     StarterKit,
//     Placeholder.configure({
//       placeholder: 'Write your own thoughts...',
//       emptyEditorClass: 'is-editor-empty',
//     }),
//   ],
//   content: '', // must be empty for placeholder
// })

// // Mount editor to #editor container
// const container = document.querySelector('#editor')
// container.appendChild(editor.options.element)
// editor.createNodeViews()


document.querySelectorAll('.editor-toolbar button').forEach(button => {
  button.addEventListener('click', () => {
    const cmd = button.dataset.cmd

    if (cmd === 'toggleBold') editor.chain().focus().toggleBold().run()
    else if (cmd === 'toggleItalic') editor.chain().focus().toggleItalic().run()
    else if (cmd === 'toggleStrike') editor.chain().focus().toggleStrike().run()
    else if (cmd === 'toggleHeading') {
      const level = parseInt(button.dataset.level)
      editor.chain().focus().toggleHeading({ level }).run()
    }

    // Toggle active state
    document.querySelectorAll('.editor-toolbar button').forEach(b => b.classList.remove('active'))
    if (editor.isActive(cmd) || (cmd === 'toggleHeading' && editor.isActive('heading', { level: parseInt(button.dataset.level) }))) {
      button.classList.add('active')
    }
  })
})

window.toggleProjects = function () {
  const projectsItem = document.querySelector('.projects')
  projectsItem.classList.toggle('active')
}
