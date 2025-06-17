function editNote(id) {
  window.location.href = '/workspace?note_id=' + id;
}
async function deleteNote(id) {
  if (!confirm('Delete this note?')) return;
  const res = await fetch('/delete-note', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ id })
  });
  const result = await res.json();
  if (result.success) {
    location.reload();
  } else {
    alert('Delete failed.');
  }
}
document.getElementById('undo-all-btn').onclick = async function() {
  if (!confirm('This will permanently delete ALL your notes. Continue?')) return;
  const res = await fetch('/delete-all-notes', { method: 'POST' });
  const result = await res.json();
  if (result.success) location.reload();
  else alert('Failed to delete all notes.');
}

// Modal logic
const settingsBtn = document.getElementById('open-settings-modal');
const settingsModal = document.getElementById('settings-modal');
const closeSettingsModal = document.getElementById('close-settings-modal');
const deleteAccountBtn = document.getElementById('delete-account-btn');
const deleteConfirmModal = document.getElementById('delete-confirm-modal');
const closeDeleteConfirm = document.getElementById('close-delete-confirm');
const cancelDeleteBtn = document.getElementById('cancel-delete-btn');

settingsBtn.onclick = () => settingsModal.classList.remove('hidden');
closeSettingsModal.onclick = () => settingsModal.classList.add('hidden');
window.onclick = function(event) {
  if (event.target === settingsModal) settingsModal.classList.add('hidden');
  if (event.target === deleteConfirmModal) deleteConfirmModal.classList.add('hidden');
}
deleteAccountBtn.onclick = () => {
  settingsModal.classList.add('hidden');
  deleteConfirmModal.classList.remove('hidden');
};
closeDeleteConfirm.onclick = () => deleteConfirmModal.classList.add('hidden');
cancelDeleteBtn.onclick = () => deleteConfirmModal.classList.add('hidden');

// Handle password change in settings modal
const usernameForm = document.getElementById('username-form');
usernameForm.addEventListener('submit', async function(e) {
  e.preventDefault();
  const editUsername = document.getElementById('edit-username').value.trim();
  let msg = document.getElementById('settings-feedback');
  if (!msg) {
    msg = document.createElement('div');
    msg.id = 'settings-feedback';
    msg.style.marginTop = '10px';
    msg.style.fontWeight = 'bold';
    usernameForm.parentNode.appendChild(msg);
  }
  if (editUsername && editUsername !== window.currentUsername) {
    const btn = usernameForm.querySelector('.save-settings-btn');
    btn.disabled = true;
    btn.textContent = 'Saving...';
    const res = await fetch('/change-username', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ new_username: editUsername })
    });
    const result = await res.json();
    btn.disabled = false;
    btn.textContent = 'Save Username';
    if (result.success) {
      msg.style.color = '#007bff';
      msg.textContent = 'Username changed successfully!';
      window.currentUsername = editUsername;
      document.querySelectorAll('.profile-info h1').forEach(h1 => h1.textContent = 'Welcome, ' + editUsername.charAt(0).toUpperCase() + editUsername.slice(1) + '!');
    } else {
      msg.style.color = '#d32f2f';
      msg.textContent = result.error || 'Failed to change username.';
    }
  } else {
    msg.style.color = '#d32f2f';
    msg.textContent = 'No username change detected.';
  }
});

// Password form
const passwordForm = document.getElementById('password-form');
passwordForm.addEventListener('submit', async function(e) {
  e.preventDefault();
  const currentPassword = document.getElementById('current-password').value;
  const newPassword = document.getElementById('new-password').value;
  const confirmNewPassword = document.getElementById('confirm-new-password').value;
  let msg = document.getElementById('settings-feedback');
  if (!msg) {
    msg = document.createElement('div');
    msg.id = 'settings-feedback';
    msg.style.marginTop = '10px';
    msg.style.fontWeight = 'bold';
    passwordForm.parentNode.appendChild(msg);
  }
  if (currentPassword && newPassword && confirmNewPassword) {
    const btn = passwordForm.querySelector('.save-settings-btn');
    btn.disabled = true;
    btn.textContent = 'Saving...';
    const res = await fetch('/change-password', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        current_password: currentPassword,
        new_password: newPassword,
        confirm_password: confirmNewPassword
      })
    });
    const result = await res.json();
    btn.disabled = false;
    btn.textContent = 'Save Password';
    if (result.success) {
      msg.style.color = '#007bff';
      msg.textContent = 'Password changed successfully!';
      document.getElementById('current-password').value = '';
      document.getElementById('new-password').value = '';
      document.getElementById('confirm-new-password').value = '';
    } else {
      msg.style.color = '#d32f2f';
      msg.textContent = result.error || 'Failed to change password.';
    }
  } else {
    msg.style.color = '#d32f2f';
    msg.textContent = 'Please fill out all password fields.';
  }
});

// Security question form
const securityForm = document.getElementById('security-form');
securityForm.addEventListener('submit', async function(e) {
  e.preventDefault();
  const securityQuestion = document.getElementById('security-question').value;
  const securityAnswer = document.getElementById('security-answer').value.trim();
  let msg = document.getElementById('settings-feedback');
  if (!msg) {
    msg = document.createElement('div');
    msg.id = 'settings-feedback';
    msg.style.marginTop = '10px';
    msg.style.fontWeight = 'bold';
    securityForm.parentNode.appendChild(msg);
  }
  if (securityQuestion && securityAnswer) {
    const btn = securityForm.querySelector('.save-settings-btn');
    btn.disabled = true;
    btn.textContent = 'Saving...';
    const res = await fetch('/change-security-question', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        question: securityQuestion,
        answer: securityAnswer
      })
    });
    const result = await res.json();
    btn.disabled = false;
    btn.textContent = 'Save Security Question';
    if (result.success) {
      msg.style.color = '#007bff';
      msg.textContent = 'Security question updated!';
      document.getElementById('security-answer').value = '';
    } else {
      msg.style.color = '#d32f2f';
      msg.textContent = result.error || 'Failed to update security question.';
    }
  } else {
    msg.style.color = '#d32f2f';
    msg.textContent = 'Please select a question and provide an answer.';
  }
});

// Store initial username for comparison
window.currentUsername = document.getElementById('edit-username')?.value;

const confirmDeleteBtn = document.getElementById('confirm-delete-btn');
const deleteConfirmInput = document.getElementById('delete-confirm-input');
const deleteConfirmModalContent = document.querySelector('#delete-confirm-modal .settings-modal-content');

confirmDeleteBtn.onclick = async function() {
  const phrase = deleteConfirmInput.value.trim();
  confirmDeleteBtn.disabled = true;
  confirmDeleteBtn.textContent = 'Deleting...';
  let msg = document.getElementById('delete-feedback');
  if (!msg) {
    msg = document.createElement('div');
    msg.id = 'delete-feedback';
    msg.style.marginTop = '10px';
    msg.style.fontWeight = 'bold';
    deleteConfirmModalContent.appendChild(msg);
  }
  const res = await fetch('/delete-account', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ confirmation: phrase })
  });
  const result = await res.json();
  confirmDeleteBtn.disabled = false;
  confirmDeleteBtn.textContent = 'Delete Account';
  if (result.success) {
    msg.style.color = '#007bff';
    msg.textContent = 'Account deleted. Redirecting...';
    setTimeout(() => { window.location.href = '/login'; }, 1200);
  } else {
    msg.style.color = '#d32f2f';
    msg.textContent = result.error || 'Failed to delete account.';
  }
};

window.editNote = editNote;
window.deleteNote = deleteNote;

