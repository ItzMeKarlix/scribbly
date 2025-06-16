import { Editor } from 'https://esm.sh/@tiptap/core@2.0.3'
import StarterKit from 'https://esm.sh/@tiptap/starter-kit@2.0.3'
import Placeholder from 'https://esm.sh/@tiptap/extension-placeholder@2.0.3'

const editor = new Editor({
    element: document.querySelector('#editor'),
    extensions: [
    StarterKit,
    Placeholder.configure({
        placeholder: 'Write your own thoughts...',
        emptyEditorClass: 'is-editor-empty',
    }),
    ],
    content: '', // must be empty for placeholder to show
});

document.querySelectorAll('.editor-toolbar button').forEach(button => {
  button.addEventListener('click', () => {
    const cmd = button.dataset.cmd
    const level = parseInt(button.dataset.level)

    // Run the corresponding command
    if (cmd === 'toggleBold') editor.chain().focus().toggleBold().run()
    else if (cmd === 'toggleItalic') editor.chain().focus().toggleItalic().run()
    else if (cmd === 'toggleStrike') editor.chain().focus().toggleStrike().run()
    else if (cmd === 'toggleHeading') editor.chain().focus().toggleHeading({ level }).run()

    // Update button states
    document.querySelectorAll('.editor-toolbar button').forEach(b => {
      const bCmd = b.dataset.cmd
      const bLevel = parseInt(b.dataset.level)
      const isActive =
        (bCmd === 'toggleBold' && editor.isActive('bold')) ||
        (bCmd === 'toggleItalic' && editor.isActive('italic')) ||
        (bCmd === 'toggleStrike' && editor.isActive('strike')) ||
        (bCmd === 'toggleHeading' && editor.isActive('heading', { level: bLevel }))

      b.classList.toggle('active', isActive)
    })
  })
})


window.toggleProjects = function () {
  const projectsItem = document.querySelector('.projects')
  projectsItem.classList.toggle('active')
}

let hasEdited = false

const printBtn = document.querySelector('.print')
const shareBtn = document.querySelector('.share')
const downloadBtn = document.querySelector('.download')
const saveBtn = document.querySelector('.save');
const titleInput = document.getElementById('note-title');
const newNoteBtn = document.querySelector('.new-project-btn');

// Enable buttons only after the user edits
editor.on('update', () => {
  const hasText = editor.getText().trim() !== '';
  const hasTitle = titleInput.value.trim() !== '';
  printBtn.disabled = !hasText;
  shareBtn.disabled = !hasText;
  downloadBtn.disabled = !hasText;
  saveBtn.disabled = !(hasText && hasTitle);
  if (hasText && hasTitle) {
    saveBtn.classList.add('highlighted');
  } else {
    saveBtn.classList.remove('highlighted');
  }
});
titleInput.addEventListener('input', () => {
  const hasText = editor.getText().trim() !== '';
  const hasTitle = titleInput.value.trim() !== '';
  saveBtn.disabled = !(hasText && hasTitle);
  if (hasText && hasTitle) {
    saveBtn.classList.add('highlighted');
  } else {
    saveBtn.classList.remove('highlighted');
  }
})

// PRINT
printBtn.addEventListener('click', () => {
  const printWindow = window.open('', '', 'width=800,height=600')
  printWindow.document.write('<pre>' + editor.getText() + '</pre>')
  printWindow.document.close()
  printWindow.focus()
  printWindow.print()
})

// SHARE
shareBtn.addEventListener('click', async () => {
  const text = editor.getText()
  if (navigator.share) {
    try {
      await navigator.share({ title: 'My Note', text })
    } catch (err) {
      alert('Sharing failed: ' + err.message)
    }
  } else {
    alert('Sharing is not supported in this browser.')
  }
})

// DOWNLOAD as .txt
downloadBtn.addEventListener('click', () => {
  const text = editor.getText()
  const blob = new Blob([text], { type: 'text/plain' })
  const link = document.createElement('a')
  link.href = URL.createObjectURL(blob)
  link.download = 'note.txt'
  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)
  URL.revokeObjectURL(link.href)
})

let currentNoteId = null;

// When editing a note, set currentNoteId from URL
function getNoteIdFromUrl() {
  const params = new URLSearchParams(window.location.search);
  return params.get('note_id');
}

// On page load, set currentNoteId if editing
currentNoteId = getNoteIdFromUrl();

// When loading a note for editing, set the fields and currentNoteId
if (window.noteContent) {
  editor.commands.setContent(window.noteContent);
}
if (window.noteTitle) {
  titleInput.value = window.noteTitle;
}

// On new note, clear currentNoteId so save will create a new note
newNoteBtn.addEventListener('click', () => {
  currentNoteId = null;
  titleInput.value = '';
  editor.commands.setContent('');
  saveBtn.disabled = true;
  saveBtn.classList.remove('highlighted');
  // Remove note_id from URL
  window.history.replaceState({}, document.title, window.location.pathname);
});

// Update save logic to only create new note if currentNoteId is null, otherwise edit
saveBtn.addEventListener('click', async () => {
  const title = titleInput.value;
  const text = editor.getHTML();
  if (text.trim() === '' || title.trim() === '') return;
  try {
    const response = await fetch('/save-note', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id: currentNoteId, title, content: text })
    });
    const result = await response.json();
    if (result.success) {
      alert('Note saved!');
      saveBtn.classList.remove('highlighted');
      // If new note, update currentNoteId if backend returns it
      if (!currentNoteId && result.id) {
        currentNoteId = result.id;
        // Optionally update URL
        window.history.replaceState({}, document.title, `?note_id=${result.id}`);
      }
    } else {
      alert('Failed to save.');
    }
  } catch (err) {
    alert('Save error: ' + err.message);
  }
});

// Set editor content and title from backend if available
if (window.noteContent) {
  editor.commands.setContent(window.noteContent);
}
if (window.noteTitle) {
  titleInput.value = window.noteTitle;
}

// NEW NOTE
newNoteBtn.addEventListener('click', () => {
  titleInput.value = '';
  editor.commands.setContent('');
  saveBtn.disabled = true;
  saveBtn.classList.remove('highlighted');
})

// Initial load
// Removed loadNotesList() call as it's no longer needed