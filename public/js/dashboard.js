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
const settingsForm = document.getElementById('settings-form');
const saveSettingsBtn = document.querySelector('.save-settings-btn');
settingsForm.addEventListener('submit', async function(e) {
  e.preventDefault();
  const editUsername = document.getElementById('edit-username').value.trim();
  const currentPassword = document.getElementById('current-password').value;
  const newPassword = document.getElementById('new-password').value;
  const confirmNewPassword = document.getElementById('confirm-new-password').value;
  let msg = document.getElementById('settings-feedback');
  if (!msg) {
    msg = document.createElement('div');
    msg.id = 'settings-feedback';
    msg.style.marginTop = '10px';
    msg.style.fontWeight = 'bold';
    settingsForm.appendChild(msg);
  }
  // Username change only
  if (editUsername && editUsername !== window.currentUsername && !currentPassword && !newPassword && !confirmNewPassword) {
    saveSettingsBtn.disabled = true;
    saveSettingsBtn.textContent = 'Saving...';
    const res = await fetch('/change-username', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ new_username: editUsername })
    });
    const result = await res.json();
    saveSettingsBtn.disabled = false;
    saveSettingsBtn.textContent = 'Save Changes';
    if (result.success) {
      msg.style.color = '#007bff';
      msg.textContent = 'Username changed successfully!';
      window.currentUsername = editUsername;
      document.querySelectorAll('.profile-info h1').forEach(h1 => h1.textContent = 'Welcome, ' + editUsername.charAt(0).toUpperCase() + editUsername.slice(1) + '!');
    } else {
      msg.style.color = '#d32f2f';
      msg.textContent = result.error || 'Failed to change username.';
    }
    return;
  }
  // Password change only
  if ((currentPassword || newPassword || confirmNewPassword) && (!editUsername || editUsername === window.currentUsername)) {
    saveSettingsBtn.disabled = true;
    saveSettingsBtn.textContent = 'Saving...';
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
    saveSettingsBtn.disabled = false;
    saveSettingsBtn.textContent = 'Save Changes';
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
    return;
  }
  // If both are changed, or neither, show a message
  if (editUsername !== window.currentUsername && (currentPassword || newPassword || confirmNewPassword)) {
    msg.style.color = '#d32f2f';
    msg.textContent = 'Please change only one section at a time.';
    return;
  }
  msg.style.color = '#d32f2f';
  msg.textContent = 'No changes detected.';
});
// Store initial username for comparison
window.currentUsername = document.getElementById('edit-username')?.value;