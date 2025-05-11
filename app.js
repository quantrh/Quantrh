// app.js: Quản lý đặt phòng họp với Supabase và hiển thị lịch dạng lưới

const SUPABASE_URL = "https://fietpawfxftojbmzuwei.supabase.co";
const SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZpZXRwYXdmeGZ0b2pibXp1d2VpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDY4NDU2MDAsImV4cCI6MjA2MjQyMTYwMH0.ANi4fxJ9pyO_5d-DCTFpHrPaZEHwSYjGnpXtf6u-Rik";

const headers = {
  apikey: SUPABASE_KEY,
  Authorization: "Bearer " + SUPABASE_KEY,
  "Content-Type": "application/json",
  "Prefer": "return=representation"
};

// Toàn cục lưu danh sách phòng và nhóm
let roomsList = [];
let teamsList = [];

// Chuyển tab chính
function showTab(tab) {
  document.getElementById('tab-calendar').style.display = tab === 'calendar' ? 'block' : 'none';
  document.getElementById('tab-parameters').style.display = tab === 'parameters' ? 'block' : 'none';
  if (tab === 'calendar') loadReservations();
}

// Chuyển subtab trong Quản lý tham số
function showSubTab(sub) {
  document.getElementById('subtab-rooms').style.display = sub === 'rooms' ? 'block' : 'none';
  document.getElementById('subtab-teams').style.display = sub === 'teams' ? 'block' : 'none';
}

// ----- LOAD & CRUD PHÒNG HỌP -----
async function loadRooms() {
  const res = await fetch(`${SUPABASE_URL}/rest/v1/meeting_rooms?select=*`, { headers });
  if (!res.ok) throw new Error('Fetch rooms failed ' + res.status);
  roomsList = await res.json();

  // Cập nhật table và dropdown
  const tbl = document.getElementById('roomTable');
  const rsel = document.getElementById('roomSelect');
  const fsel = document.getElementById('filterRoom');
  tbl.innerHTML = '';
  rsel.innerHTML = '<option value="">Chọn phòng</option>';
  fsel.innerHTML = '<option value="">Tất cả phòng</option>';

  roomsList.forEach(r => {
    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td><input id="roomName_${r.id}" value="${r.name}"/></td>
      <td><input id="roomLoc_${r.id}"  value="${r.location}"/></td>
      <td><button onclick="editRoom(${r.id})">Sửa</button></td>
      <td><button onclick="deleteRoom(${r.id})">Xóa</button></td>
    `;
    tbl.appendChild(tr);
    rsel.innerHTML += `<option value="${r.id}">${r.name}</option>`;
    fsel.innerHTML += `<option value="${r.id}">${r.name}</option>`;
  });
}

async function addRoom() {
  const name = document.getElementById('roomName').value.trim();
  const loc  = document.getElementById('roomLocation').value.trim();
  if (!name || !loc) return alert('Nhập tên & vị trí');
  const res = await fetch(`${SUPABASE_URL}/rest/v1/meeting_rooms`, {
    method: 'POST', headers, body: JSON.stringify({ name, location: loc })
  });
  if (!res.ok) return alert('Thêm phòng thất bại');
  alert('Thêm phòng thành công');
  document.getElementById('roomName').value = '';
  document.getElementById('roomLocation').value = '';
  await loadRooms();
}

async function editRoom(id) {
  const name = document.getElementById(`roomName_${id}`).value.trim();
  const loc  = document.getElementById(`roomLoc_${id}`).value.trim();
  const res = await fetch(`${SUPABASE_URL}/rest/v1/meeting_rooms?id=eq.${id}`, {
    method: 'PATCH', headers, body: JSON.stringify({ name, location: loc })
  });
  if (!res.ok) return alert('Cập nhật phòng thất bại');
  alert('Cập nhật phòng thành công');
  await loadRooms();
  loadReservations();
}

async function deleteRoom(id) {
  if (!confirm('Xác nhận xóa phòng?')) return;
  const res = await fetch(`${SUPABASE_URL}/rest/v1/meeting_rooms?id=eq.${id}`, {
    method: 'DELETE', headers
  });
  if (!res.ok) return alert('Xóa phòng thất bại');
  alert('Xóa phòng thành công');
  await loadRooms();
  loadReservations();
}

// ----- LOAD & CRUD NHÓM -----
async function loadTeams() {
  const res = await fetch(`${SUPABASE_URL}/rest/v1/work_teams?select=*`, { headers });
  if (!res.ok) throw new Error('Fetch teams failed ' + res.status);
  teamsList = await res.json();

  const tbl  = document.getElementById('teamTable');
  const tsel = document.getElementById('teamSelect');
  const ftsel= document.getElementById('filterTeam');
  tbl.innerHTML = '';
  tsel.innerHTML = '<option value="">Chọn nhóm</option>';
  ftsel.innerHTML= '<option value="">Tất cả nhóm</option>';

  teamsList.forEach(t => {
    const tr = document.createElement('tr');
    tr.innerHTML = `
      <td><input id="teamName_${t.id}" value="${t.name}"/></td>
      <td>
        <select id="teamType_${t.id}">
          <option value="nội bộ"  ${t.type==='nội bộ' ? 'selected':''}>Nội bộ</option>
          <option value="bên ngoài"${t.type==='bên ngoài'?'selected':''}>Bên ngoài</option>
        </select>
      </td>
      <td><button onclick="editTeam(${t.id})">Sửa</button></td>
      <td><button onclick="deleteTeam(${t.id})">Xóa</button></td>
    `;
    tbl.appendChild(tr);
    tsel.innerHTML  += `<option value="${t.id}">${t.name}</option>`;
    ftsel.innerHTML+= `<option value="${t.id}">${t.name}</option>`;
  });
}

async function addTeam() {
  const name = document.getElementById('teamName').value.trim();
  const type = document.getElementById('teamType').value;
  if (!name) return alert('Nhập tên nhóm');
  const res = await fetch(`${SUPABASE_URL}/rest/v1/work_teams`, {
    method: 'POST', headers, body: JSON.stringify({ name, type })
  });
  if (!res.ok) return alert('Thêm nhóm thất bại');
  alert('Thêm nhóm thành công');
  document.getElementById('teamName').value = '';
  await loadTeams();
}

async function editTeam(id) {
  const name = document.getElementById(`teamName_${id}`).value.trim();
  const type = document.getElementById(`teamType_${id}`).value;
  const res = await fetch(`${SUPABASE_URL}/rest/v1/work_teams?id=eq.${id}`, {
    method: 'PATCH', headers, body: JSON.stringify({ name, type })
  });
  if (!res.ok) return alert('Cập nhật nhóm thất bại');
  alert('Cập nhật nhóm thành công');
  await loadTeams();
  loadReservations();
}

async function deleteTeam(id) {
  if (!confirm('Xác nhận xóa nhóm?')) return;
  const res = await fetch(`${SUPABASE_URL}/rest/v1/work_teams?id=eq.${id}`, {
    method: 'DELETE', headers
  });
  if (!res.ok) return alert('Xóa nhóm thất bại');
  alert('Xóa nhóm thành công');
  await loadTeams();
  loadReservations();
}

// ----- ĐẶT LỊCH MỚI -----
async function addReservation() {
  const date       = document.getElementById('selectedDate').value;
  const room_id    = document.getElementById('roomSelect').value;
  const team_id    = document.getElementById('teamSelect').value;
  const start_time = document.getElementById('startTime').value;
  const end_time   = document.getElementById('endTime').value;
  const purpose    = document.getElementById('purpose').value;
  if (!date || !room_id || !team_id || !start_time || !end_time) {
    return alert('Vui lòng nhập đầy đủ thông tin');
  }

  // Kiểm tra xung đột
  const checkRes = await fetch(
    `${SUPABASE_URL}/rest/v1/reservations?date=eq.${date}&room_id=eq.${room_id}&select=start_time,end_time`,
    { headers }
  );
  const existing = await checkRes.json();
  if (existing.some(e => !(end_time <= e.start_time || start_time >= e.end_time))) {
    return alert('❌ Xung đột lịch! Chọn khung giờ khác.');
  }

  // Gửi POST
  const resp = await fetch(`${SUPABASE_URL}/rest/v1/reservations`, {
    method: 'POST',
    headers,
    body: JSON.stringify({ date, room_id, team_id, start_time, end_time, purpose })
  });
  if (!resp.ok) {
    console.error(await resp.text());
    return alert('❌ Đặt lịch không thành công');
  }
  alert('✅ Đặt lịch thành công');
  loadReservations();
}

// ----- LOAD & HIỂN THỊ LỊCH -----
async function loadReservations() {
  const date = document.getElementById('selectedDate').value;
  if (!date) return;

  // Xóa cũ
  document.getElementById('calendarView').innerHTML = '';

  const roomFilter = document.getElementById('filterRoom').value;
  const teamFilter = document.getElementById('filterTeam').value;

  const resp = await fetch(
    `${SUPABASE_URL}/rest/v1/reservations?date=eq.${date}&select=*`,
    { headers }
  );
  if (!resp.ok) {
    console.error(await resp.text());
    return alert('Lỗi khi tải lịch');
  }
  let data = await resp.json();
  if (roomFilter) data = data.filter(r => r.room_id == roomFilter);
  if (teamFilter) data = data.filter(r => r.team_id == teamFilter);

  renderCalendar(data);
}

function renderCalendar(meetings) {
  const view = document.getElementById('calendarView');
  const rowHeight = 50; // px per hour
  const hours = Array.from({ length: 21 - 6 + 1 }, (_, i) => 6 + i);

  // Tính spans và skipMap
  const spansByRoom = {}, skipMap = {};
  meetings.forEach(m => {
    const startH = +m.start_time.slice(0,2);
    const endH   = +m.end_time.slice(0,2);
    const idx     = hours.indexOf(startH);
    const span    = Math.max(endH - startH, 1);
    if (idx >= 0) {
      spansByRoom[m.room_id] = spansByRoom[m.room_id] || [];
      spansByRoom[m.room_id].push({ idx, span, meeting: m });
    }
  });
  Object.keys(spansByRoom).forEach(rid => {
    skipMap[rid] = Array(hours.length).fill(false);
    spansByRoom[rid].forEach(s => {
      for (let i = s.idx + 1; i < s.idx + s.span; i++) {
        skipMap[rid][i] = true;
      }
    });
  });

  // Vẽ bảng
  let html = '<table style="width:100%;border-collapse:collapse;">';
  html += '<tr><th style="border:1px solid #ccc;padding:4px;height:'+rowHeight+'px;">Giờ</th>'
       + roomsList.map(r=>
           `<th style="border:1px solid #ccc;padding:4px;height:${rowHeight}px;">${r.name}</th>`
         ).join('')
       + '</tr>';

  hours.forEach((h, rowIdx) => {
    const hh = String(h).padStart(2,'0') + ':00';
    html += `<tr style="height:${rowHeight}px;"><td style="border:1px solid #ccc;padding:4px;">${hh}</td>`;
    roomsList.forEach(room => {
      if (skipMap[room.id] && skipMap[room.id][rowIdx]) return;
      const entry = (spansByRoom[room.id]||[]).find(s => s.idx === rowIdx);
      if (entry) {
        const team = teamsList.find(t => t.id === entry.meeting.team_id);
        html += `<td rowspan="${entry.span}"
                    style="border:1px solid #ccc;padding:4px;height:${entry.span*rowHeight}px;background:#90caf9;">
                   <strong>${entry.meeting.start_time}-${entry.meeting.end_time}</strong><br>
                   ${entry.meeting.purpose}<br>
                   <em>Nhóm: ${team?team.name:'—'}</em>
                 </td>`;
      } else {
        html += '<td style="border:1px solid #ccc;padding:4px;"></td>';
      }
    });
    html += '</tr>';
  });

  html += '</table>';
  view.innerHTML = html;
}

document.addEventListener('DOMContentLoaded', async () => {
  showTab('calendar');
  await loadRooms();
  await loadTeams();
  document.getElementById('selectedDate').value = new Date().toISOString().split('T')[0];
  loadReservations();
});
