/**
 * ==============================================================================
 * TÂN THẾ GIỚI — CONCEPT & DESIGN EXECUTIVE DASHBOARD
 * Core Application Logic & Interactive Systems (app.js)
 * ==============================================================================
 */

document.addEventListener('DOMContentLoaded', () => {
  initAudio();
  initNavigation();
  initInteractiveMap();
  initTimelineCalculator();
  initHardwareSimulator();
  initTechTreeAndCrafts();
  initMcpToolsDirectory();
  initExportReport();
});

/* ==============================================================================
   1. WEB AUDIO API SYNTHESIZER (SUBTLE UI AUDIO FEEDBACK)
   ============================================================================== */
let audioCtx = null;
let isAudioEnabled = true;

function initAudio() {
  const toggleBtn = document.getElementById('audioToggleBtn');
  const icon = document.getElementById('audioIcon');

  toggleBtn.addEventListener('click', () => {
    isAudioEnabled = !isAudioEnabled;
    icon.textContent = isAudioEnabled ? '🔊' : '🔇';
    showToast(isAudioEnabled ? 'Đã bật âm thanh hiệu ứng' : 'Đã tắt âm thanh');
    if (isAudioEnabled) playTone(587.33, 'sine', 0.15, 0.05); // D5
  });
}

function playTone(freq, type = 'sine', duration = 0.12, gainVal = 0.04) {
  if (!isAudioEnabled) return;
  try {
    if (!audioCtx) {
      audioCtx = new (window.AudioContext || window.webkitAudioContext)();
    }
    if (audioCtx.state === 'suspended') {
      audioCtx.resume();
    }

    const osc = audioCtx.createOscillator();
    const gain = audioCtx.createGain();

    osc.type = type;
    osc.frequency.setValueAtTime(freq, audioCtx.currentTime);

    gain.gain.setValueAtTime(gainVal, audioCtx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.0001, audioCtx.currentTime + duration);

    osc.connect(gain);
    gain.connect(audioCtx.destination);

    osc.start();
    osc.stop(audioCtx.currentTime + duration);
  } catch {
    // Audio context policy fallback
  }
}

function playChime(freqs = [440, 659.25, 880]) {
  if (!isAudioEnabled) return;
  freqs.forEach((f, i) => {
    setTimeout(() => playTone(f, 'sine', 0.25, 0.03), i * 60);
  });
}

/* ==============================================================================
   2. MAIN NAVIGATION SYSTEM
   ============================================================================== */
function initNavigation() {
  const tabs = document.querySelectorAll('.nav-tab');
  const panes = document.querySelectorAll('.tab-pane');

  tabs.forEach(tab => {
    tab.addEventListener('click', () => {
      const targetId = tab.getAttribute('data-tab');
      
      tabs.forEach(t => t.classList.remove('active'));
      panes.forEach(p => p.classList.remove('active'));

      tab.classList.add('active');
      const targetPane = document.getElementById(`pane-${targetId}`);
      if (targetPane) targetPane.classList.add('active');

      playTone(523.25, 'sine', 0.12, 0.03); // C5
    });
  });
}

/* ==============================================================================
   3. INTERACTIVE SVG MAP & ELEVATION INSPECTOR
   ============================================================================== */
const POI_DATA = {
  1: {
    title: "Đại Cao Ốc Mega-Office Skyscraper (X=0, Z=0)",
    desc: "Trụ sở dùng chung giữa Văn phòng Thị Trưởng, Văn phòng Người Chăn Chiên và Viện Hàn Lâm R&D. Sân đỗ trực thăng Skydeck Tầng 15 (+724.6m).",
    elevation: "+710 m (+124.6m tòa nhà)",
    distance: "0 km (Tâm Lõi)",
    transitTime: "0 phút",
    industry: "Quản Trị Vĩ Mô & Sứ Mạng Hòa Bình"
  },
  2: {
    title: "Cảng Hòa Bình (Peace Port)",
    desc: "Cửa ngõ tiếp đón lữ khách từ các lục địa xa xôi. Nơi neo đậu tàu viễn dương, trạm kiểm dịch hữu nghị và trung tâm lưu trú ban đầu.",
    elevation: "+0 m (Mực nước biển)",
    distance: "12.0 km (Đông Nam)",
    transitTime: "24 phút (Tram Express)",
    industry: "Tiếp Đón Lữ Khách & Giao Thương Biển"
  },
  3: {
    title: "Đại Nông Trường Lúa Mì Huyện Đông",
    desc: "Thảo nguyên trù phú với cánh đồng lúa mì vàng óng. Hưởng hệ số bội thu Đất Lành 1.6x, cung cấp 100% lương thực sạch cho toàn thành phố.",
    elevation: "+220 m (Thung lũng Đông)",
    distance: "8.5 km (Hướng Đông)",
    transitTime: "17 phút (Metro Nan Hoa)",
    industry: "Nông Nghiệp Sinh Thái (CERT_AGRI_CROPS)"
  },
  4: {
    title: "Khu Điều Dưỡng Suối Khoáng Onsen Huyện Bắc",
    desc: "Rừng thông bạt ngàn dưới chân núi tuyết. Bể ngâm khoáng nóng tự nhiên phục hồi 100% sinh lực và năng lượng cho cư dân sau giờ lao động.",
    elevation: "+480 m (Chân núi tuyết)",
    distance: "9.2 km (Hướng Bắc)",
    transitTime: "19 phút (Bus Xanh)",
    industry: "Y Học Phục Hồi & Trị Liệu Khoáng"
  },
  5: {
    title: "Cánh Đồng Điện Gió & Xưởng Cơ Khí Huyện Tây",
    desc: "Trung tâm công nghiệp chế tạo, gia công cơ khí chính xác CNC và cụm tuabin gió sạch cung cấp 45% điện lưới cho Tân Thế Giới.",
    elevation: "+180 m (Cao nguyên gió Tây)",
    distance: "8.8 km (Hướng Tây)",
    transitTime: "18 phút (Tram Vành Đai)",
    industry: "Cơ Khí & Hao Mòn (CERT_AUTO_MECHANIC)"
  },
  6: {
    title: "Cảng Cá & Duyên Hải Huyện Nam",
    desc: "Làng chài truyền thống và cảng cá công nghệ cao. Khai thác hải sản bền vững, xưởng chế biến nước mắm truyền thống và bến du thuyền.",
    elevation: "+5 m (Vịnh phía Nam)",
    distance: "10.5 km (Hướng Nam)",
    transitTime: "21 phút (Metro Nam)",
    industry: "Thủy Hải Sản (CERT_MARITIME_FISHING)"
  },
  7: {
    title: "Trạm Cáp Treo Vách Đá Dựng Đứng",
    desc: "Hệ thống cáp treo tĩnh âm vượt vách đá dựng đứng từ cao độ +200m lên +710m trong 4.5 phút, trang bị cảm biến rà soát an toàn cáp tự động.",
    elevation: "+500 m (Vách đá)",
    distance: "3.2 km (Tây Bắc)",
    transitTime: "4.5 phút (Cáp Treo)",
    industry: "Giao Thông Vách Đá & Bảo Trì Cáp"
  },
  8: {
    title: "Đại Thánh Đường Đỉnh Vát",
    desc: "Trung tâm tâm linh hiệp thông của toàn thể cư dân. Nơi cử hành Thánh Lễ lúc 11:40 Thứ Tư & Chủ Nhật, cùng bữa tiệc Bác ái Agape ấm cúng.",
    elevation: "+710 m (Cao nguyên)",
    distance: "350 m từ Mega-Office",
    transitTime: "3 phút (Đi bộ phố râm mát)",
    industry: "Phụng Vụ, Thánh Ca & Mục Vụ"
  },
  9: {
    title: "Nhà Hát Âm Nhạc & Phố Đi Bộ Nghệ Thuật",
    desc: "Không gian 100% dành cho người đi bộ, cà phê Ghibli, tiệm bánh mì thơm nức và các sân khấu biểu diễn âm nhạc đường phố (Busking) mỗi chiều.",
    elevation: "+710 m (Cao nguyên)",
    distance: "400 m từ Mega-Office",
    transitTime: "4 phút (Đi bộ)",
    industry: "Nghệ Thuật & Ẩm Thực (CERT_MUSIC_PERFORMANCE)"
  },
  10: {
    title: "Viện Hàn Lâm Khoa Học Cao Nguyên (HAS Lab)",
    desc: "Nơi quy tụ các nhà khoa học hàng đầu. Nghiên cứu lớp phủ nano chống mài mòn máy móc, pin tinh thể thạch anh và công nghệ sinh học đất lành.",
    elevation: "+720 m (Mega-Office Lab)",
    distance: "0 km (Tầng Cao Skyscraper)",
    transitTime: "1 phút (Thang máy siêu tốc)",
    industry: "Nghiên Cứu R&D (CERT_APPLIED_RND)"
  }
};

const DISTRICT_DATA = {
  east: {
    title: "Huyện Đông — Nông Trường & Lương Thực",
    desc: "Vựa lúa mì hữu cơ, trang trại bò sữa và trung tâm chế biến bột mì. Cung ứng lương thực nuôi sống toàn bộ cư dân Tân Thế Giới.",
    elevation: "+220 m",
    distance: "8.5 km",
    transitTime: "17 phút",
    industry: "Nông Nghiệp (CERT_AGRI_CROPS)"
  },
  west: {
    title: "Huyện Tây — Cơ Khí & Năng Lượng Gió",
    desc: "Xưởng tiện CNC, sửa chữa tram, đúc hợp kim siêu nhẹ và cánh đồng tuabin gió sạch cung cấp điện năng cho toàn cao nguyên.",
    elevation: "+180 m",
    distance: "8.8 km",
    transitTime: "18 phút",
    industry: "Cơ Khí & Năng Lượng (CERT_AUTO_MECHANIC)"
  },
  north: {
    title: "Huyện Bắc — Rừng Thông & Suối Khoáng Onsen",
    desc: "Rừng thông bạt ngàn 1500 km², khu điều dưỡng suối khoáng nóng Onsen và đường mòn leo núi tuyết hùng vĩ.",
    elevation: "+480 m",
    distance: "9.2 km",
    transitTime: "19 phút",
    industry: "Lâm Nghiệp & Y Học Phục Hồi"
  },
  south: {
    title: "Huyện Nam — Cảng Hòa Bình & Duyên Hải",
    desc: "Bến cảng quốc tế, làng chài hải sản, xưởng đóng tàu composite và bãi biển cát trắng đón ánh bình minh anime.",
    elevation: "+5 m",
    distance: "11.0 km",
    transitTime: "22 phút",
    industry: "Hàng Hải & Thủy Sản"
  }
};

let currentZoom = 1;

function initInteractiveMap() {
  const mapSvg = document.getElementById('interactiveMap');
  const poiGroups = document.querySelectorAll('.poi-group');
  const districtWedges = document.querySelectorAll('.district-wedge');
  const ringRoads = document.querySelectorAll('.ring-road');
  const spokeLines = document.querySelectorAll('.spoke-line');

  // POI Clicks
  poiGroups.forEach(group => {
    group.addEventListener('click', (e) => {
      e.stopPropagation();
      const poiId = group.getAttribute('data-poi');
      const data = POI_DATA[poiId];
      if (data) {
        updateInspector(data);
        playTone(659.25, 'sine', 0.15, 0.04); // E5
      }
    });
  });

  // District Clicks
  districtWedges.forEach(wedge => {
    wedge.addEventListener('click', (e) => {
      e.stopPropagation();
      const distId = wedge.getAttribute('data-district');
      const data = DISTRICT_DATA[distId];
      if (data) {
        updateInspector(data);
        playTone(493.88, 'sine', 0.15, 0.04); // B4
      }
    });
  });

  // Ring Roads Hover Tooltip
  ringRoads.forEach(ring => {
    ring.addEventListener('mouseenter', () => {
      const ringName = ring.getAttribute('data-ring');
      showToast(ringName);
    });
  });

  // Spoke Lines Hover Tooltip
  spokeLines.forEach(spoke => {
    spoke.addEventListener('mouseenter', () => {
      const spokeName = spoke.getAttribute('data-spoke');
      showToast(spokeName);
    });
  });

  // Zoom Controls
  document.getElementById('zoomInBtn').addEventListener('click', () => {
    if (currentZoom < 2.5) {
      currentZoom += 0.3;
      applyZoom(mapSvg);
    }
  });

  document.getElementById('zoomOutBtn').addEventListener('click', () => {
    if (currentZoom > 0.7) {
      currentZoom -= 0.3;
      applyZoom(mapSvg);
    }
  });

  document.getElementById('resetMapBtn').addEventListener('click', () => {
    currentZoom = 1;
    applyZoom(mapSvg);
    updateInspector(POI_DATA[1]);
  });
}

function applyZoom(svg) {
  svg.style.transform = `scale(${currentZoom})`;
  svg.style.transition = 'transform 0.3s cubic-bezier(0.16, 1, 0.3, 1)';
  playTone(440, 'triangle', 0.08, 0.02);
}

function updateInspector(data) {
  document.getElementById('inspectorTitle').textContent = data.title;
  document.getElementById('inspectorDesc').textContent = data.desc;
  document.getElementById('statElevation').textContent = data.elevation;
  document.getElementById('statDistance').textContent = data.distance;
  document.getElementById('statTransitTime').textContent = data.transitTime;
  document.getElementById('statIndustry').textContent = data.industry;
}

/* ==============================================================================
   4. TIMELINE CALCULATOR (1:20 GOLDEN RATIO)
   ============================================================================== */
function initTimelineCalculator() {
  const realInput = document.getElementById('realSecInput');
  const gameOutput = document.getElementById('gameMinOutput');
  const yieldOutput = document.getElementById('offlineYieldEstimate');

  function calculate() {
    const realSec = Math.max(1, parseInt(realInput.value) || 0);
    // 3.0 real seconds = 1 game minute
    const gameMin = Math.floor(realSec / 3.0);
    const hours = Math.floor(gameMin / 60);
    const mins = gameMin % 60;

    let timeStr = `${gameMin} phút`;
    if (hours > 0) {
      timeStr += ` (${hours}h ${mins}m)`;
    }
    gameOutput.value = timeStr;

    // Economic yield: ~0.1042 Đ tax per game minute
    const estYield = (gameMin * 0.1042).toFixed(2);
    yieldOutput.textContent = `+${estYield} Đ`;
  }

  realInput.addEventListener('input', calculate);
}

/* ==============================================================================
   5. INTEL IRIS XE HARDWARE BUDGET SIMULATOR
   ============================================================================== */
function initHardwareSimulator() {
  const sliderPop = document.getElementById('sliderPopulation');
  const valPop = document.getElementById('valPopulation');

  const sliderStream = document.getElementById('sliderStreaming');
  const valStream = document.getElementById('valStreaming');

  const weatherBtns = document.querySelectorAll('.weather-btn');
  let currentWeather = 'sunny';

  const chkMultiMesh = document.getElementById('toggleMultiMesh');
  const chkOctahedral = document.getElementById('toggleOctahedral');
  const chkShadow = document.getElementById('toggleShadow');
  const chkCrowd = document.getElementById('toggleCrowdSpline');

  const resetBtn = document.getElementById('resetSimBtn');

  function recalculate() {
    const pop = parseInt(sliderPop.value);
    const stream = parseInt(sliderStream.value);

    valPop.textContent = `${pop.toLocaleString()} dân`;
    valStream.textContent = `${stream.toLocaleString()} m`;

    // Calculation formulas matching Intel Iris Xe specs
    let baseDrawCalls = 320;
    let baseTriangles = 450000;
    let baseVram = 0.85; // GB

    // Population impact
    const popFactor = pop / 2400.0;
    baseDrawCalls += Math.round(popFactor * 220);
    baseTriangles += Math.round(popFactor * 320000);
    baseVram += (popFactor * 0.25);

    // Streaming radius impact
    const streamFactor = stream / 1500.0;
    baseDrawCalls += Math.round(streamFactor * 160);
    baseTriangles += Math.round(streamFactor * 380000);
    baseVram += (streamFactor * 0.35);

    // Weather impact
    if (currentWeather === 'rain') {
      baseDrawCalls += 85; // Particle emitters
      baseTriangles += 90000;
      baseVram += 0.12;
    } else if (currentWeather === 'mist') {
      baseDrawCalls += 50;
      baseVram += 0.08;
    } else if (currentWeather === 'liturgy') {
      baseDrawCalls += 180; // High crowd concentration
      baseTriangles += 250000;
      baseVram += 0.22;
    }

    // Optimization discounts
    if (chkMultiMesh.checked) {
      baseDrawCalls -= 180;
    } else {
      baseDrawCalls += 350;
      baseTriangles += 200000;
    }

    if (chkOctahedral.checked) {
      baseDrawCalls -= 120;
      baseTriangles -= 350000;
    } else {
      baseDrawCalls += 280;
      baseTriangles += 600000;
    }

    if (chkShadow.checked) {
      baseDrawCalls -= 70;
    } else {
      baseDrawCalls += 220;
    }

    if (chkCrowd.checked) {
      if (currentWeather === 'liturgy') {
        baseDrawCalls -= 140;
      }
    } else {
      if (currentWeather === 'liturgy') {
        baseDrawCalls += 420;
        baseTriangles += 500000;
      }
    }

    // Clamping results
    const drawCalls = Math.max(220, Math.round(baseDrawCalls));
    const triangles = Math.max(300000, Math.round(baseTriangles));
    const vram = Math.max(0.65, parseFloat(baseVram.toFixed(2)));

    // Calculate Estimated FPS
    let fps = 60;
    if (drawCalls > 1200 || triangles > 1600000 || vram > 1.8) {
      fps = Math.max(18, Math.round(60 - ((drawCalls - 1200) / 25) - ((triangles - 1600000) / 40000)));
    } else if (drawCalls > 850 || triangles > 1200000) {
      fps = Math.max(45, Math.round(60 - ((drawCalls - 850) / 35)));
    }

    const frameTime = (1000.0 / fps).toFixed(1);
    const cpuTime = (frameTime * 0.38).toFixed(1);
    const gpuTime = (frameTime * 0.62).toFixed(1);

    // Update UI Elements
    document.getElementById('metricDrawCalls').textContent = `${drawCalls} / 1200`;
    document.getElementById('metricTriangles').textContent = `${(triangles / 1000).toFixed(0)}k / 1.8M`;
    document.getElementById('metricVram').textContent = `${vram} GB / 1.8 GB`;
    document.getElementById('metricFrameTime').textContent = `${frameTime} ms (CPU: ${cpuTime}ms • GPU: ${gpuTime}ms)`;

    // Bar fills
    const barDC = document.getElementById('barDrawCalls');
    const pctDC = Math.min(100, Math.round((drawCalls / 1200) * 100));
    barDC.style.width = `${pctDC}%`;
    barDC.className = `bar-fill ${pctDC > 85 ? 'red' : pctDC > 65 ? 'yellow' : 'green'}`;

    const barTri = document.getElementById('barTriangles');
    const pctTri = Math.min(100, Math.round((triangles / 1800000) * 100));
    barTri.style.width = `${pctTri}%`;
    barTri.className = `bar-fill ${pctTri > 80 ? 'red' : pctTri > 60 ? 'yellow' : 'green'}`;

    const barVram = document.getElementById('barVram');
    const pctVram = Math.min(100, Math.round((vram / 1.8) * 100));
    barVram.style.width = `${pctVram}%`;
    barVram.className = `bar-fill ${pctVram > 90 ? 'red' : 'teal'}`;

    // Update FPS Gauge
    const gaugeNum = document.getElementById('gaugeFpsNum');
    const statusText = document.getElementById('fpsStatusText');
    const statusSub = document.getElementById('fpsStatusSub');
    const circle = document.getElementById('fpsCircle');
    const advisorText = document.getElementById('advisorText');

    gaugeNum.textContent = fps;

    if (fps >= 58) {
      circle.style.borderColor = '#10b981';
      circle.style.boxShadow = '0 0 25px rgba(16, 185, 129, 0.4)';
      statusText.textContent = 'HIỆU NĂNG HOÀN HẢO (60 FPS)';
      statusText.style.color = '#34d399';
      statusSub.textContent = 'Không phát hiện hiện tượng nghẽn bus bộ nhớ. Game vận hành mượt mà chuẩn 60 FPS.';
      advisorText.innerHTML = '<strong>Chẩn Đoán Kỹ Thuật:</strong> Hệ thống hoạt động tối ưu trong ngân sách Intel Iris Xe. Mọi cơ chế LoD và MultiMesh đang phát huy tác dụng triệt để.';
    } else if (fps >= 45) {
      circle.style.borderColor = '#f59e0b';
      circle.style.boxShadow = '0 0 25px rgba(245, 158, 11, 0.4)';
      statusText.textContent = `ỔN ĐỊNH CÓ TẢI (${fps} FPS)`;
      statusText.style.color = '#fcd34d';
      statusSub.textContent = 'Bắt đầu có tải đồ họa nhẹ. Vẫn đáp ứng tốt trải nghiệm chơi mượt mà không xé hình.';
      advisorText.innerHTML = '<strong>Khuyến Nghị:</strong> Draw Calls đang ở mức 800 - 1000. Hãy duy trì MultiMeshInstance3D và tránh tăng bán kính streaming quá 3000m.';
    } else {
      circle.style.borderColor = '#f43f5e';
      circle.style.boxShadow = '0 0 25px rgba(244, 63, 94, 0.5)';
      statusText.textContent = `CẢNH BÁO NGHẼN BUS RAM (${fps} FPS)`;
      statusText.style.color = '#fb7185';
      statusSub.textContent = 'Cảnh báo sụt giảm khung hình nghiêm trọng do vượt quá giới hạn Draw Calls hoặc thiếu cơ chế LOD!';
      advisorText.innerHTML = '<strong>CẢNH BÁO CẤP BÁCH:</strong> Đã tắt các cơ chế tối ưu hoặc quá tải cư dân giờ Phụng Vụ. Bật ngay <em>Crowd Spline</em> và <em>Octahedral Impostor LOD</em> để cứu vãn FPS!';
    }
  }

  // Event Listeners
  sliderPop.addEventListener('input', recalculate);
  sliderStream.addEventListener('input', recalculate);

  weatherBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      weatherBtns.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      currentWeather = btn.getAttribute('data-weather');
      playTone(400, 'sine', 0.1, 0.03);
      recalculate();
    });
  });

  [chkMultiMesh, chkOctahedral, chkShadow, chkCrowd].forEach(chk => {
    chk.addEventListener('change', () => {
      playTone(chk.checked ? 600 : 350, 'sine', 0.1, 0.03);
      recalculate();
    });
  });

  resetBtn.addEventListener('click', () => {
    sliderPop.value = 2400;
    sliderStream.value = 1500;
    weatherBtns.forEach(b => b.classList.remove('active'));
    weatherBtns[0].classList.add('active');
    currentWeather = 'sunny';
    chkMultiMesh.checked = true;
    chkOctahedral.checked = true;
    chkShadow.checked = true;
    chkCrowd.checked = true;
    recalculate();
    playChime();
    showToast('Đã khôi phục thông số chuẩn 60 FPS!');
  });

  recalculate();
}

/* ==============================================================================
   6. 14 CRAFT SECTORS & 20-TIER CONTINUOUS R&D TECH TREE
   ============================================================================== */
const TECH_BRANCHES = {
  materials: {
    name: "Vật Liệu & Chống Mài Mòn",
    icon: "⚙️",
    color: "gold",
    totalBenefit: "-21.0% Tốc độ hao mòn cơ học",
    tiers: [
      { t: 1, title: "Dầu Thực Vật Bôi Trơn Bản Lề", effect: "-0.5% hao mòn cơ học ban đầu" },
      { t: 2, title: "Tinh Lọc Dầu Khoáng Suối Tự Nhiên", effect: "-0.5% hao mòn ổ bi xe tram (Lũy kế: -1.0%)" },
      { t: 3, title: "Đệm Cao Su Sinh Học Giảm Chấn", effect: "-1.0% chấn động mài mòn bánh xe (Lũy kế: -2.0%)" },
      { t: 4, title: "Xử Lý Nhiệt Ram Bề Mặt Thép", effect: "+1.0% độ cứng bánh răng cối xay và lò nướng (-3.0%)" },
      { t: 5, title: "Hợp Kim Đồng - Thiếc Chống Ma Sát", effect: "-1.0% ma sát trục quay tuabin (Lũy kế: -4.0%)" },
      { t: 6, title: "Sơn Lót Gốc Nhựa Thông Tự Nhiên", effect: "-1.0% gỉ sét khung xe do sương mù (-5.0%)" },
      { t: 7, title: "Dầu Bôi Trơn Chịu Nhiệt Cao", effect: "-1.0% kẹt linh kiện lò nướng và máy ép (-6.0%)" },
      { t: 8, title: "Hợp Kim Nhôm Siêu Nhẹ Cáp Treo", effect: "-1.0% độ giãn cáp tời trên vách đá (-7.0%)" },
      { t: 9, title: "Phốt Chắn Bụi Vi Hạt Xưởng Mộc", effect: "-1.0% bụi mạt gỗ lọt vào động cơ cưa (-8.0%)" },
      { t: 10, title: "Lớp Mạ Crom Cứng Xi-lanh Khí", effect: "-1.0% mài mòn máy nén khí và pít-tông (-9.0%)" },
      { t: 11, title: "Men Gốm Sứ Chịu Lửa Cách Nhiệt", effect: "-1.0% nứt vỡ gạch thành lò (-10.0%)" },
      { t: 12, title: "Dầu Pha Hạt Graphite Mịn Bôi Trơn Ray", effect: "-1.0% độ mài mòn ray tram (-11.0%)" },
      { t: 13, title: "Hợp Kim Titan Xốp Khung Gầm", effect: "-1.0% ứng suất tải trọng lên trục bánh xe (-12.0%)" },
      { t: 14, title: "Polymer Kháng Kiềm & Muối Biển", effect: "-1.0% ăn mòn tàu thuyền Cảng Nam (-13.0%)" },
      { t: 15, title: "Cảm Biến Vi Đo Độ Rung Chẩn Đoán Sớm", effect: "-1.5% sự cố bất ngờ nhờ bảo trì kịp thời (-14.5%)" },
      { t: 16, title: "Màng Oxit Nhôm Anode Hóa Bề Mặt", effect: "-1.5% trầy xước và ô-xy hóa vỏ máy (-16.0%)" },
      { t: 17, title: "Phủ Màng Kim Cương Nhân Tạo DLC", effect: "+1.5% tuổi thọ dao phay tiện CNC (-17.5%)" },
      { t: 18, title: "Hạt Nano Phân Tán Giảm Ma Sát Khô", effect: "-1.5% hao mòn khi khởi động nguội máy (-19.0%)" },
      { t: 19, title: "Polymer Vi Nang Tự Chữa Lành Vết Nứt", effect: "-1.0% nứt gãy vi mô kết cấu kim loại (-20.0%)" },
      { t: 20, title: "Công Nghệ Lớp Phủ Nano Tự Phục Hồi Toàn Diện", effect: "Triệt tiêu trọn vẹn -21.0% hao mòn toàn đô thị!" }
    ]
  },
  agri: {
    name: "Nông Nghiệp Sinh Thái & Đất Lành",
    icon: "🌾",
    color: "green",
    totalBenefit: "+21.0% Sản lượng hữu cơ (1.60x ➔ 1.85x)",
    tiers: [
      { t: 1, title: "Sàng Lọc Hạt Giống Đều Hạt", effect: "+0.5% sản lượng thu hoạch lúa mì đầu mùa" },
      { t: 2, title: "Ủ Phân Hữu Cơ Rơm Rạ Vi Sinh", effect: "+0.5% độ phì nhiêu tầng đất mặt (Lũy kế: +1.0%)" },
      { t: 3, title: "Luân Canh Cây Đậu Đỗ Cố Định Đạm", effect: "+1.0% năng suất vụ sau tự nhiên (+2.0%)" },
      { t: 4, title: "Bẫy Đèn Bắt Côn Trùng Sinh Học", effect: "-1.0% thất thoát hạt lúa non (+3.0%)" },
      { t: 5, title: "Kênh Dẫn Nước Suối Giữ Ẩm Đất", effect: "+1.0% sức sống mầm lúa Huyện Đông (+4.0%)" },
      { t: 6, title: "Giống Lúa Mì Chịu Gió Lạnh Triền Dốc", effect: "+1.0% tỷ lệ kết hạt chắc bông (+5.0%)" },
      { t: 7, title: "Men Vi Sinh Kích Hoạt Đất Đỉnh Núi", effect: "+1.0% hiệu quả hấp thụ khoáng chất (+6.0%)" },
      { t: 8, title: "Nhà Kính Tre Ghép Đón Sáng Tối Đa", effect: "+1.0% năng suất rau xanh mùa sương (+7.0%)" },
      { t: 9, title: "Khẩu Phần Cỏ Ủ Men Cho Bò Sữa", effect: "+1.0% sản lượng sữa tươi béo thơm (+8.0%)" },
      { t: 10, title: "Lưới Bẫy Sương Bổ Sung Ẩm Tự Nhiên", effect: "+1.0% sản lượng vườn rau thủy canh (+9.0%)" },
      { t: 11, title: "Tỉa Cành Tán Tròn Đón Nắng Cây Quả", effect: "+1.0% độ đường và sản lượng quả (+10.0%)" },
      { t: 12, title: "Vi Sinh Vật Hòa Tan Lân Tự Nhiên", effect: "+1.0% sức phát triển rễ cây lương thực (+11.0%)" },
      { t: 13, title: "Giá Thể Xơ Dừa Hoạt Tính Tuần Hoàn", effect: "+1.0% tốc độ thu hoạch rau sạch (+12.0%)" },
      { t: 14, title: "Men Bánh Mì Lên Men Chậm Tinh Khiết", effect: "+1.0% độ nở xốp và dinh dưỡng bánh mì (+13.0%)" },
      { t: 15, title: "Đàn Ong Bản Địa Thụ Phấn Tự Nhiên", effect: "+1.5% tỷ lệ đậu trái vườn dâu & táo (+14.5%)" },
      { t: 16, title: "Dung Dịch Phun Sương Ion Khoáng Sinh Học", effect: "+1.5% dưỡng chất và năng suất rau (+16.0%)" },
      { t: 17, title: "Cỏ Linh Lăng Chịu Sương Muối Huyện Bắc", effect: "+1.5% thức ăn xanh đàn gia súc (+17.5%)" },
      { t: 18, title: "Hệ Thống Thủy Canh Đa Tầng Đèn Quang Phổ", effect: "+1.5% sản lượng Huyện Đông (+19.0%)" },
      { t: 19, title: "Chế Phẩm Nấm Rễ Cộng Sinh Mycorrhiza", effect: "+1.0% độ trù phú đất canh tác (+20.0%)" },
      { t: 20, title: "Đỉnh Cao Phước Lành Nông Nghiệp Hoàn Mỹ", effect: "Tăng trọn vẹn +21.0% sản lượng hữu cơ toàn diện!" }
    ]
  },
  energy: {
    name: "Năng Lượng Sạch SCADA",
    icon: "⚡",
    color: "teal",
    totalBenefit: "+21.0% Hiệu suất điện lưới thông minh",
    tiers: [
      { t: 1, title: "Cân Bằng Động Cánh Tuabin Gió", effect: "+0.5% hiệu suất quay ở tốc độ gió thấp" },
      { t: 2, title: "Lõi Dây Dẫn Đồng Tinh Khiết Bện Chặt", effect: "-0.5% tổn thất điện trở trên tuyến (+1.0%)" },
      { t: 3, title: "Dầu Cách Điện Biến Áp Gốc Thực Vật", effect: "+1.0% khả năng chịu tải đỉnh trạm (+2.0%)" },
      { t: 4, title: "Cảm Biến Tự Động Định Hướng Gió", effect: "+1.0% góc đón gió hữu ích của tuabin (+3.0%)" },
      { t: 5, title: "Chống Sét Lan Truyền Vách Đá Đỉnh Vát", effect: "-1.0% nguy cơ ngắt điện do dông sét (+4.0%)" },
      { t: 6, title: "Sơn Chống Bám Bụi Cánh Quạt Tuabin", effect: "+1.0% khí động học quay liên tục (+5.0%)" },
      { t: 7, title: "Rãnh Hướng Dòng Thủy Điện Suối Tự Nhiên", effect: "+1.0% lưu lượng nước vào máy phát (+6.0%)" },
      { t: 8, title: "Tụ Bù Tự Động Công Suất Phản Kháng", effect: "-1.0% sụt áp giờ cao điểm phụng vụ (+7.0%)" },
      { t: 9, title: "Đèn Đường LED Cảm Biến Ánh Sáng Tự Nhiên", effect: "Tiết kiệm 1.0% điện chiếu sáng anime (+8.0%)" },
      { t: 10, title: "Pin Tinh Thể Đơn Lớp Hấp Thu Ánh Sáng Tán Xạ", effect: "+1.0% điện năng ngày sương mù (+9.0%)" },
      { t: 11, title: "Bộ Biến Tần Inverter Sóng Sin Chuẩn", effect: "+1.0% hiệu suất chuyển đổi dòng điện (+10.0%)" },
      { t: 12, title: "Cánh Tuabin Sợi Thủy Tinh Khí Động Mới", effect: "+1.0% sản lượng điện gió Huyện Tây (+11.0%)" },
      { t: 13, title: "Hồ Thủy Điện Tích Năng Trên Đồi", effect: "+1.0% nguồn dự trữ điện điều tiết (+12.0%)" },
      { t: 14, title: "Lưới Điện Vi Mô Phân Khu Tự Cân Bằng", effect: "-1.0% nguy cơ quá tải cục bộ (+13.0%)" },
      { t: 15, title: "Giám Sát Nhiệt Hồng Ngoại Đường Cáp Ngầm", effect: "-1.5% rủi ro phóng điện (+14.5%)" },
      { t: 16, title: "Pin Lưu Trữ Muối Khoáng Tự Nhiên Ban Đêm", effect: "+1.5% dung lượng tích điện dự phòng (+16.0%)" },
      { t: 17, title: "Thuật Toán SCADA Dự Báo Gió Đỉnh Núi", effect: "+1.5% hiệu quả điều độ điện năng (+17.5%)" },
      { t: 18, title: "Lớp Bán Dẫn Nano Bề Mặt Quang Năng", effect: "+1.5% hấp thụ quang phổ cực tím (+19.0%)" },
      { t: 19, title: "Pin Tinh Thể Thạch Anh Không Thoái Hóa", effect: "+1.0% độ ổn định điện áp vĩnh cửu (+20.0%)" },
      { t: 20, title: "Hệ Thống SCADA Tự Trị Toàn Đô Thị 2.0", effect: "Tối ưu trọn vẹn +21.0% hiệu suất năng lượng sạch!" }
    ]
  },
  robotics: {
    name: "Tự Động Hóa Nhân Đạo",
    icon: "🤖",
    color: "blue",
    totalBenefit: "+21.0% Hiệu suất SCM kho RAM",
    tiers: [
      { t: 1, title: "Con Lăn Trượt Chuyển Pallet Gỗ", effect: "+0.5% tốc độ xếp dỡ kho RAM" },
      { t: 2, title: "Cơ Cấu Đòn Bẩy Trợ Lực Cửa Kho Nặng", effect: "-0.5% sức kéo cơ bắp cho thủ kho (+1.0%)" },
      { t: 3, title: "Cân Điện Tử Đồng Bộ Tự Động", effect: "+1.0% độ chính xác kiểm kê vật tư (+2.0%)" },
      { t: 4, title: "Máng Trượt Trọng Lực Cối Xay Lúa Mì", effect: "+1.0% tốc độ nạp bột mì vào bao (+3.0%)" },
      { t: 5, title: "Bàn Nâng Thủy Lực Đạp Chân Xưởng Cơ Khí", effect: "-1.0% thời gian gá đặt linh kiện (+4.0%)" },
      { t: 6, title: "Xe Đẩy Hàng 4 Bánh Có Phanh Tự Hãm Dốc", effect: "+1.0% an toàn vận chuyển nội bộ (+5.0%)" },
      { t: 7, title: "Cần Tời Cáp Mềm Dựng Khung Gỗ", effect: "+1.0% tốc độ dựng cột nhà ở (+6.0%)" },
      { t: 8, title: "Cữ Chặn Tự Động Máy Cưa Gỗ Xưởng Mộc", effect: "+1.0% độ chuẩn xác thanh gỗ xẻ (+7.0%)" },
      { t: 9, title: "Băng Chuyền Cao Su Chuyển Bao Bột Mì", effect: "+1.0% lưu lượng hàng xuất kho (+8.0%)" },
      { t: 10, title: "Máy Trộn Bột Hai Trục Đảo Tốc Độ", effect: "+1.0% năng suất thợ làm bánh mì (+9.0%)" },
      { t: 11, title: "Xe Nâng Tay Trợ Lực Điện Kiện Đá", effect: "+1.0% tốc độ cấp đá xây dựng (+10.0%)" },
      { t: 12, title: "Đồ Gá Nhanh Khí Nén Máy Tiện CNC", effect: "+1.0% năng suất sản xuất chi tiết (+11.0%)" },
      { t: 13, title: "Cảm Biến Quang Học Đếm Sản Phẩm ERP", effect: "+1.0% tốc độ đối soát kho (+12.0%)" },
      { t: 14, title: "Tay Nâng Khí Nén Đỡ Động Cơ Nặng", effect: "Giảm 1.0% mệt mỏi cho thợ sửa xe (+13.0%)" },
      { t: 15, title: "Cần Cẩu Tháp Điều Khiển Từ Xa Góc Rộng", effect: "+1.5% tốc độ cẩu lắp công trình (+14.5%)" },
      { t: 16, title: "Xe Kéo Điện Tự Hành Bến Cá Huyện Nam", effect: "+1.5% tốc độ luân chuyển cá tươi (+16.0%)" },
      { t: 17, title: "Cánh Tay Kẹp Hỗ Trợ Hàn Ray Tram", effect: "-1.5% thời gian xử lý hỏng hóc lớn (+17.5%)" },
      { t: 18, title: "Đầu Cắt Đĩa Xoay Thủy Lực Đào Hầm", effect: "+1.5% tiến độ thi công metro xuyên núi (+19.0%)" },
      { t: 19, title: "Robot Bò Dây Kiểm Tra An Toàn Cáp Treo", effect: "+1.0% độ chính xác rà soát cáp (+20.0%)" },
      { t: 20, title: "Hệ Thống Tự Động Hóa Nhân Đạo Hợp Nhất", effect: "Giải phóng triệt để công việc nặng nhọc (+21.0%)" }
    ]
  },
  wellness: {
    name: "Y Học & Sinh Thái",
    icon: "🌿",
    color: "violet",
    totalBenefit: "+21.0% Tốc độ hồi phục thể lực & Hòa hợp",
    tiers: [
      { t: 1, title: "Trà Thảo Mộc Sấy Lạnh Giữ Hương", effect: "Hồi phục thể lực nhanh hơn 0.5% sau giờ đi bộ" },
      { t: 2, title: "Đệm Bông Tự Nhiên Thoáng Khí Ký Túc Xá", effect: "+0.5% chất lượng giấc ngủ sâu (+1.0%)" },
      { t: 3, title: "Bể Lọc Cát Thạch Anh Nước Suối Nóng", effect: "+1.0% độ tinh khiết dòng khoáng Onsen (+2.0%)" },
      { t: 4, title: "Muối Khoáng Ngâm Chân Thảo Dược", effect: "Giảm 1.0% mỏi cơ sau giờ làm việc (+3.0%)" },
      { t: 5, title: "Khử Khuẩn Nước Bằng Sục Khí Ozone Tự Nhiên", effect: "+1.0% an toàn nước sinh hoạt (+4.0%)" },
      { t: 6, title: "Bột Khoáng Dược Thảo Ngâm Bồn Gỗ Thông", effect: "+1.0% tốc độ hồi phục sinh lực (+5.0%)" },
      { t: 7, title: "Rãnh Lọc Sỏi Sinh Học Tuần Hoàn Nước Xám", effect: "Giảm 1.0% thất thoát nước đô thị (+6.0%)" },
      { t: 8, title: "Sưởi Gốm Hồng Ngoại Phòng Thay Đồ Onsen", effect: "Giảm 1.0% sốc nhiệt gió lạnh cao nguyên (+7.0%)" },
      { t: 9, title: "Phòng Xông Hơi Đá Muối Khoáng Huyện Bắc", effect: "+1.0% tuần hoàn máu và sảng khoái (+8.0%)" },
      { t: 10, title: "Lọc Than Hoạt Tính Gáo Dừa Tự Nhiên", effect: "+1.0% độ ngọt và khoáng nước uống (+9.0%)" },
      { t: 11, title: "Quy Trình Giãn Cơ Vận Động Viên Thể Thao", effect: "Giảm 1.0% nguy cơ căng cứng cơ (+10.0%)" },
      { t: 12, title: "Đèn Phổ Quang Ban Mai Trong Phòng Ở", effect: "+1.0% sảng khoái khi thức dậy (+11.0%)" },
      { t: 13, title: "Màng Thẩm Thấu Sinh Học Tuần Hoàn Nước 100%", effect: "+1.0% tỷ lệ tái tạo nước ngọt (+12.0%)" },
      { t: 14, title: "Liệu Pháp Tinh Dầu Thông Rừng Nguyên Sinh", effect: "Giảm 1.0% mệt mỏi tâm trí (+13.0%)" },
      { t: 15, title: "Bồn Tắm Bùn Khoáng Nóng Giàu Silic", effect: "+1.5% độ dẻo dai cơ khớp (+14.5%)" },
      { t: 16, title: "Cảm Biến Sinh Thái Rà Soát Tự Động Nước Thải", effect: "+1.5% độ trong lành môi trường (+16.0%)" },
      { t: 17, title: "Ánh Sáng Sinh Học Bước Sóng Ấm Thư Giãn", effect: "+1.5% tâm trạng an hòa cư dân (+17.5%)" },
      { t: 18, title: "Hệ Thống Lọc Không Khí Bằng Cây Dương Xỉ", effect: "+1.5% độ trong sạch không khí (+19.0%)" },
      { t: 19, title: "Tuần Hoàn Sinh Thái Không Rác Thải Zero-Waste", effect: "Tiết kiệm 1.0% tài nguyên kho RAM (+20.0%)" },
      { t: 20, title: "Hòa Nhịp Sóng Âm Trị Liệu & Khoáng Vi Lượng", effect: "Tối ưu trọn vẹn +21.0% thể lực, hòa hợp tuyệt đối!" }
    ]
  }
};

const CRAFT_SECTORS = [
  {
    name: "1. Nông Nghiệp & Cây Lương Thực",
    cert: "CERT_AGRI_CROPS",
    desc: "Canh tác lúa mì, lúa mạch, ngô và các loại ngũ cốc hữu cơ trên cánh đồng Huyện Đông. Đóng góp trực tiếp vào kho bột mì của tiệm bánh.",
    location: "Trang trại Huyện Đông",
    quota: "Hạn ngạch đề xuất: 30-50 suất",
    role: "Thu hoạch sản vật với hệ số bội thu Đất Lành 1.6x"
  },
  {
    name: "2. Cơ Khí Ô Tô, Xe Điện & Tram",
    cert: "CERT_AUTO_MECHANIC",
    desc: "Chẩn đoán hao mòn máy móc, bảo dưỡng hệ thống truyền động xe điện, ray tram và động cơ xe buggy Thị Trưởng.",
    location: "Xưởng Cơ Khí Huyện Tây",
    quota: "Hạn ngạch đề xuất: 20-35 suất",
    role: "Khắc phục triệt để hao mòn cơ học, bảo dưỡng ray tram"
  },
  {
    name: "3. Kiến Trúc, Quy Hoạch & Mộc Mỹ Nghệ",
    cert: "CERT_CARPENTRY",
    desc: "Thi công nhà gỗ thông, lắp dựng khung giàn vách đá, đóng bàn ghế phòng trà và đồ nội thất gỗ cao cấp phong cách Ghibli.",
    location: "Xưởng Mộc & Công Trường",
    quota: "Hạn ngạch đề xuất: 15-25 suất",
    role: "Xây dựng nhà vườn, khu ký túc xá và cầu treo vách núi"
  },
  {
    name: "4. Hành Chính Công & Dịch Vụ Một Cửa",
    cert: "CERT_CIVIC_ADMIN",
    desc: "Vận hành bộ máy Một Cửa 5 bước, thụ lý căn cước công dân, phân bổ nhà ở và giải quyết quyền lợi lao động tự động.",
    location: "Tòa Mega-Office & 4 Tòa Vệ Tinh",
    quota: "Hạn ngạch đề xuất: 12-18 suất",
    role: "Đảm bảo nguyên tắc Không Vi Quản Lý cho Thị Trưởng"
  },
  {
    name: "5. Tài Chính, Kế Toán & Ngân Hàng",
    cert: "CERT_FINANCE_BANKING",
    desc: "Vận hành Ngân hàng Nhà nước, quản trị thuật toán in tiền theo kho RAM, cấp tín dụng 0% và đối soát thuế đô thị 5%.",
    location: "Trụ Sở Ngân Hàng Nhà Nước",
    quota: "Hạn ngạch đề xuất: 10-15 suất",
    role: "Triệt tiêu đầu cơ và lạm phát tiền tệ"
  },
  {
    name: "6. Bánh Mì Thủ Công & Ẩm Thực",
    cert: "CERT_BAKERY_CHEF",
    desc: "Nướng bánh mì Baguette nóng giòn, bánh ngọt men tự nhiên và bánh quy bơ phục vụ cư dân tại các góc phố râm mát.",
    location: "Tiệm Bánh Phố Đi Bộ Đỉnh Vát",
    quota: "Hạn ngạch đề xuất: 15-20 suất",
    role: "Tạo nguồn hồi phục HP và niềm vui ẩm thực đời thường"
  },
  {
    name: "7. Y Học Phục Hồi & Dược Thảo",
    cert: "CERT_DOCTOR_PHYSICIAN",
    desc: "Khám chữa bệnh dự phòng, tư vấn dinh dưỡng thanh xuân và trị liệu phục hồi thể lực bằng liệu pháp khoáng Onsen.",
    location: "Bệnh Viện Đỉnh Vát & Onsen Bắc",
    quota: "Hạn ngạch đề xuất: 12-18 suất",
    role: "Duy trì thể trạng sung mãn vĩnh cửu cho cư dân"
  },
  {
    name: "8. Năng Lượng Tái Tạo & Lưới Điện SCADA",
    cert: "CERT_POWER_GRID",
    desc: "Vận hành trạm biến áp Đỉnh Vát, cánh đồng tuabin gió Huyện Tây và hệ thống pin lưu trữ muối khoáng tự nhiên.",
    location: "Trạm Biến Áp & Cánh Đồng Gió",
    quota: "Hạn ngạch đề xuất: 15-22 suất",
    role: "Đảm bảo tram và cáp treo chạy liên tục không sụt áp"
  },
  {
    name: "9. Truyền Thông, Ký Giả & Bản Tin",
    cert: "CERT_JOURNALISM_MEDIA",
    desc: "Xuất bản bản tin đô thị, sản xuất podcast phát thanh thanh xuân và thông báo lịch trình phụng vụ toàn thành phố.",
    location: "Đài Phát Thanh Tòa Mega-Office",
    quota: "Hạn ngạch đề xuất: 8-12 suất",
    role: "Gắn kết thông tin huynh đệ giữa 5 Huyện"
  },
  {
    name: "10. Âm Nhạc, Biểu Diễn & Thánh Ca",
    cert: "CERT_MUSIC_PERFORMANCE",
    desc: "Biểu diễn nhạc acoustic đường phố (Busking), hòa tấu piano phòng trà và phụng vụ ca đoàn tôn vinh Chúa trong Thánh Lễ.",
    location: "Nhà Hát Âm Nhạc & Đại Thánh Đường",
    quota: "Hạn ngạch đề xuất: 20-30 suất",
    role: "Nuôi dưỡng tâm hồn an hòa và niềm hân hoan thánh thiện"
  },
  {
    name: "11. Kiểm Chuẩn Môi Trường & Sinh Thái",
    cert: "CERT_ENVIRONMENTAL_HEALTH",
    desc: "Giám sát tuần hoàn rác thải 100% Zero-Waste, đo đạc độ sạch của nước ngầm và kiểm định chất lượng vật phẩm xuất xưởng.",
    location: "Viện Môi Trường Huyện Bắc",
    quota: "Hạn ngạch đề xuất: 8-10 suất",
    role: "Giữ vững vẻ đẹp thiên nhiên thuần khiết kiểu Shinkai"
  },
  {
    name: "12. Khai Thác & Nuôi Trồng Thủy Sản",
    cert: "CERT_MARITIME_FISHING",
    desc: "Đánh bắt cá biển sinh thái bền vững, nuôi trồng ngọc trai và rong biển sạch tại vùng duyên hải Huyện Nam.",
    location: "Cảng Cá & Vịnh Huyện Nam",
    quota: "Hạn ngạch đề xuất: 15-25 suất",
    role: "Cung cấp nguồn protein và vi khoáng biển tự nhiên"
  },
  {
    name: "13. Mục Vụ, Tư Vấn Tâm Lý & Hòa Bình",
    cert: "CERT_PASTORAL_COUNSELING",
    desc: "Lắng nghe tâm tư, hòa giải đời sống huynh đệ, điều phối tình nguyện viên NHVC và chăm lo tinh thần cho cư dân.",
    location: "Đại Thánh Đường & Trạm Vệ Tinh",
    quota: "Hạn ngạch đề xuất: 25-40 suất",
    role: "Duy trì Chỉ Số Hòa Hợp Xã Hội tuyệt đối 100%"
  },
  {
    name: "14. Nghiên Cứu Khoa Học & Sáng Chế R&D",
    cert: "CERT_APPLIED_RND",
    desc: "Nghiên cứu vật liệu nano chống mài mòn, lai tạo giống cây trồng chịu lạnh và thiết kế bản vẽ công nghệ toàn dân.",
    location: "Viện Hàn Lâm HAS Skyscraper",
    quota: "Hạn ngạch đề xuất: 15-25 suất",
    role: "Sản sinh điểm tri thức KBU mở khóa cây công nghệ 20 bậc"
  }
];

function initTechTreeAndCrafts() {
  const subTabs = document.querySelectorAll('.sub-tab');
  const subPanes = document.querySelectorAll('.sub-pane');

  subTabs.forEach(tab => {
    tab.addEventListener('click', () => {
      subTabs.forEach(t => t.classList.remove('active'));
      subPanes.forEach(p => p.classList.remove('active'));
      tab.classList.add('active');
      const target = tab.getAttribute('data-sub');
      document.getElementById(`sub-${target}`).classList.add('active');
      playTone(493.88, 'sine', 0.1, 0.03);
    });
  });

  // Render Tech Tree
  renderTechTree('all');

  // Branch filter pills
  const branchPills = document.querySelectorAll('.branch-pill');
  branchPills.forEach(pill => {
    pill.addEventListener('click', () => {
      branchPills.forEach(p => p.classList.remove('active'));
      pill.classList.add('active');
      const branchKey = pill.getAttribute('data-branch');
      renderTechTree(branchKey);
      playTone(523.25, 'sine', 0.1, 0.03);
    });
  });

  // Render Crafts
  renderCrafts();

  // Search input for crafts
  const craftSearch = document.getElementById('craftSearchInput');
  craftSearch.addEventListener('input', (e) => {
    const q = e.target.value.toLowerCase().trim();
    renderCrafts(q);
  });
}

function renderTechTree(filterBranch = 'all') {
  const container = document.getElementById('techTreeGrid');
  container.innerHTML = '';

  let branchesToRender = Object.keys(TECH_BRANCHES);
  if (filterBranch !== 'all') {
    branchesToRender = [filterBranch];
  }

  branchesToRender.forEach(bKey => {
    const branch = TECH_BRANCHES[bKey];
    branch.tiers.forEach(item => {
      const card = document.createElement('div');
      card.className = `tech-node-card ${item.t <= 5 ? 'unlocked' : ''}`;
      card.innerHTML = `
        <div class="tech-node-header">
          <span class="tier-badge">BẬC ${item.t} / 20</span>
          <span class="tech-branch-tag">${branch.icon} ${branch.name}</span>
        </div>
        <h5 class="tech-node-title">${item.title}</h5>
        <span class="tech-node-effect">${item.effect}</span>
      `;

      card.addEventListener('click', () => {
        card.classList.toggle('unlocked');
        playTone(card.classList.contains('unlocked') ? 783.99 : 392, 'sine', 0.15, 0.04);
        showToast(`Đề án: ${item.title} (${item.effect})`);
      });

      container.appendChild(card);
    });
  });
}

function renderCrafts(query = '') {
  const container = document.getElementById('craftsCardGrid');
  container.innerHTML = '';

  const filtered = CRAFT_SECTORS.filter(c => {
    if (!query) return true;
    return c.name.toLowerCase().includes(query) ||
           c.cert.toLowerCase().includes(query) ||
           c.desc.toLowerCase().includes(query) ||
           c.role.toLowerCase().includes(query);
  });

  document.getElementById('craftCountBadge').textContent = `${filtered.length} / 14 Khối Ngành`;

  filtered.forEach(c => {
    const card = document.createElement('div');
    card.className = 'craft-card';
    card.innerHTML = `
      <div class="craft-header">
        <h4 class="craft-name">${c.name}</h4>
        <span class="cert-code">${c.cert}</span>
      </div>
      <p class="craft-desc">${c.desc}</p>
      <div class="craft-meta">
        <div>📍 <strong>Nơi làm việc:</strong> ${c.location}</div>
        <div>🎯 <strong>Vai trò:</strong> ${c.role}</div>
        <div>🎓 <strong>Đề xuất:</strong> <span style="color: var(--gold);">${c.quota}</span></div>
      </div>
    `;
    container.appendChild(card);
  });
}

/* ==============================================================================
   7. GODOT-MCP 42 TOOLS EXPLORER
   ============================================================================== */
const MCP_EXTENSIONS_DATA = [
  // 1. Navigation Tools (7)
  { ext: "Navigation", name: "navigation-defaults", desc: "Trả về thông số khởi đầu khuyến nghị (radius, distance, max speed) cho 2D/3D NavigationAgent." },
  { ext: "Navigation", name: "navigation-region-create", desc: "Tạo node NavigationRegion3D cho chunk đô thị xung quanh người chơi." },
  { ext: "Navigation", name: "navigation-region-set-mesh", desc: "Gán tài nguyên NavigationMesh nướng cục bộ vào NavigationRegion3D." },
  { ext: "Navigation", name: "navigation-agent-create", desc: "Tạo node NavigationAgent3D hỗ trợ tìm đường và né tránh vật cản động." },
  { ext: "Navigation", name: "navigation-agent-configure", desc: "Cập nhật các thuộc tính bán kính né tránh, tốc độ và khoảng cách đích." },
  { ext: "Navigation", name: "navigation-link-create", desc: "Tạo đường kết nối NavigationLink3D giữa 2 điểm vách núi hoặc bậc thang." },
  { ext: "Navigation", name: "navigation-get", desc: "Đọc cấu hình scalar của node Navigation (chế độ chỉ đọc)." },

  // 2. Particles Tools (5)
  { ext: "Particles", name: "particles-defaults", desc: "Trả về cấu hình gợi ý cho bộ phát hạt thời tiết (Mưa rào anime, Tuyết rơi Huyện Bắc)." },
  { ext: "Particles", name: "particles-create", desc: "Tạo node GpuParticles3D trong scene đang mở." },
  { ext: "Particles", name: "particles-configure", desc: "Tinh chỉnh số lượng hạt, vận tốc phát, trọng lực và hướng gió." },
  { ext: "Particles", name: "particles-set-emitting", desc: "Bật hoặc tắt trạng thái phát hạt của hệ thống thời tiết." },
  { ext: "Particles", name: "particles-get", desc: "Đọc thông số hiện tại của hệ thống hạt." },

  // 3. Tilemap Tools (6)
  { ext: "Tilemap", name: "tilemap-create", desc: "Tạo TileMapLayer 2D phục vụ giao diện sơ đồ bản đồ trên Tablet Civic OS." },
  { ext: "Tilemap", name: "tilemap-set-tileset", desc: "Gán TileSet tài nguyên bản đồ vào TileMapLayer." },
  { ext: "Tilemap", name: "tilemap-set-cell", desc: "Thiết lập một ô tile theo tọa độ bản đồ và tọa độ atlas." },
  { ext: "Tilemap", name: "tilemap-erase-cell", desc: "Xóa một ô tile trên bản đồ trở về rỗng." },
  { ext: "Tilemap", name: "tilemap-get-used-cells", desc: "Liệt kê danh sách tất cả các ô đang được sử dụng." },
  { ext: "Tilemap", name: "tilemap-clear", desc: "Xóa toàn bộ các ô tile trên layer trong khi vẫn giữ nguyên TileSet." },

  // 4. Animation Tools (7)
  { ext: "Animation", name: "animation-defaults", desc: "Trả về cấu hình độ dài clip và loop mode cho hoạt ảnh Anime." },
  { ext: "Animation", name: "animation-player-create", desc: "Tạo node AnimationPlayer trong Scene nhân vật." },
  { ext: "Animation", name: "animation-library-add", desc: "Thêm thư viện AnimationLibrary mới vào AnimationPlayer." },
  { ext: "Animation", name: "animation-create", desc: "Tạo một hoạt ảnh Animation cụ thể (Đi bộ, Lái buggy, Vẫy tay)." },
  { ext: "Animation", name: "animation-add-track", desc: "Thêm track giá trị hoặc 3D transform vào Animation clip." },
  { ext: "Animation", name: "animation-insert-key", desc: "Chèn keyframe thời gian vào track hoạt ảnh." },
  { ext: "Animation", name: "animation-get", desc: "Đọc danh sách clip và cấu hình keyframe của AnimationPlayer." },

  // 5. CSG Tools (7)
  { ext: "CSG", name: "csg-defaults", desc: "Trả về thông số khởi đầu cho khối hình học CSG (Box, Sphere, Cylinder)." },
  { ext: "CSG", name: "csg-box-create", desc: "Tạo khối CsgBox3D phác thảo nhanh nhà ở hoặc bệ chờ tram." },
  { ext: "CSG", name: "csg-sphere-create", desc: "Tạo khối CsgSphere3D phục vụ tạo vòm mái nhà thờ." },
  { ext: "CSG", name: "csg-cylinder-create", desc: "Tạo khối CsgCylinder3D cho cột trụ kiến trúc cổ điển." },
  { ext: "CSG", name: "csg-combiner-create", desc: "Tạo container CsgCombiner3D gom nhóm các khối CSG con." },
  { ext: "CSG", name: "csg-set-operation", desc: "Đặt phép toán Boolean: Union (Hợp), Intersection (Giao), Subtraction (Trừ)." },
  { ext: "CSG", name: "csg-get", desc: "Đọc thông số kích thước và phép toán của node CSG." },

  // 6. GridMap Tools (7)
  { ext: "GridMap", name: "gridmap-defaults", desc: "Trả về cấu hình ô lưới chuẩn cho xây dựng mô đun 3D." },
  { ext: "GridMap", name: "gridmap-create", desc: "Tạo node GridMap để xếp đặt các khối nhà tiền chế." },
  { ext: "GridMap", name: "gridmap-set-mesh-library", desc: "Gán thư viện MeshLibrary các mẫu nhà và vỉa hè." },
  { ext: "GridMap", name: "gridmap-set-cell", desc: "Đặt một mô đun công trình vào vị trí lưới tọa độ." },
  { ext: "GridMap", name: "gridmap-clear-cell", desc: "Xóa một khối công trình tại vị trí ô lưới." },
  { ext: "GridMap", name: "gridmap-clear", desc: "Xóa toàn bộ bản đồ ô lưới GridMap." },
  { ext: "GridMap", name: "gridmap-get", desc: "Đọc thông số cấu hình và danh sách ô đã đặt." },

  // 7. PhantomCamera Tools (7)
  { ext: "PhantomCamera", name: "phantomcamera-defaults", desc: "Trả về thông số camera điện ảnh (Priority, Follow Mode, Damping)." },
  { ext: "PhantomCamera", name: "phantomcamera-host-create", desc: "Tạo PhantomCameraHost dưới Camera3D chính của người chơi." },
  { ext: "PhantomCamera", name: "phantomcamera-create", desc: "Tạo node PhantomCamera3D cho góc quay điện ảnh Anime." },
  { ext: "PhantomCamera", name: "phantomcamera-set-follow", desc: "Cấu hình đối tượng bám đuôi (Thị trưởng, Xe buggy, NPC)." },
  { ext: "PhantomCamera", name: "phantomcamera-set-look-at", desc: "Cấu hình mục tiêu hướng nhìn tự động cho camera." },
  { ext: "PhantomCamera", name: "phantomcamera-set-priority", desc: "Nâng hạ Priority để chuyển đổi mượt mà giữa các Rigs camera." },
  { ext: "PhantomCamera", name: "phantomcamera-get", desc: "Đọc trạng thái hiện thời của PhantomCamera3D." },

  // 8. Beehave Tools (6)
  { ext: "Beehave", name: "beehave-defaults", desc: "Trả về khung xương cây hành vi chuẩn cho AI cư dân." },
  { ext: "Beehave", name: "beehave-tree-create", desc: "Tạo node gốc BeehaveTree điều khiển quyết định NPC." },
  { ext: "Beehave", name: "beehave-add-composite", desc: "Thêm node Selector hoặc Sequence vào cây hành vi." },
  { ext: "Beehave", name: "beehave-add-decorator", desc: "Thêm Inverter hoặc Limiter điều tiết tần suất thực thi." },
  { ext: "Beehave", name: "beehave-add-leaf", desc: "Thêm node lá Action (Làm việc, Đi bộ, Cầu nguyện, Nghỉ ngơi)." },
  { ext: "Beehave", name: "beehave-get", desc: "Đọc toàn bộ cây cấu trúc hành vi của NPC." },

  // 9. Dialogic Tools (5)
  { ext: "Dialogic", name: "dialogic-defaults", desc: "Trả về mẫu tài nguyên kịch bản đối thoại và nhân vật." },
  { ext: "Dialogic", name: "dialogic-timeline-create", desc: "Tạo file timeline hội thoại Anime (.dtl) kèm sự kiện đầu tiên." },
  { ext: "Dialogic", name: "dialogic-character-create", desc: "Tạo hồ sơ nhân vật hội thoại (.dch) với tên và màu đại diện." },
  { ext: "Dialogic", name: "dialogic-timeline-add-text", desc: "Thêm lời thoại và biểu cảm nhân vật vào kịch bản." },
  { ext: "Dialogic", name: "dialogic-get", desc: "Đọc nội dung và các nhánh rẽ lựa chọn của file đối thoại." },

  // 10. Terrain3D Tools (6)
  { ext: "Terrain3D", name: "terrain3d-defaults", desc: "Trả về thông số tối ưu cho địa hình 500km2 (Region size, LOD)." },
  { ext: "Terrain3D", name: "terrain3d-create", desc: "Tạo node Terrain3D kết nối hệ thống độ cao liên tục." },
  { ext: "Terrain3D", name: "terrain3d-set-data-directory", desc: "Thiết lập thư mục res:// lưu dữ liệu bản đồ độ cao." },
  { ext: "Terrain3D", name: "terrain3d-set-region-size", desc: "Cấu hình kích thước vùng region địa hình phù hợp GPU." },
  { ext: "Terrain3D", name: "terrain3d-set-material", desc: "Gán Terrain3DMaterial hỗ trợ shader cỏ và đất đá Cel-shaded." },
  { ext: "Terrain3D", name: "terrain3d-get", desc: "Đọc cấu hình vùng và bộ nhớ của Terrain3D." }
];

function initMcpToolsDirectory() {
  const searchInput = document.getElementById('mcpSearchInput');
  const catPills = document.querySelectorAll('.cat-pill');
  let currentCat = 'all';

  function filterAndRender() {
    const q = searchInput.value.toLowerCase().trim();
    const tbody = document.getElementById('mcpToolsTableBody');
    tbody.innerHTML = '';

    const filtered = MCP_EXTENSIONS_DATA.filter(item => {
      const matchCat = (currentCat === 'all' || item.ext === currentCat);
      const matchQ = (!q || item.name.toLowerCase().includes(q) || item.desc.toLowerCase().includes(q) || item.ext.toLowerCase().includes(q));
      return matchCat && matchQ;
    });

    filtered.forEach(item => {
      const tr = document.createElement('tr');
      tr.innerHTML = `
        <td><strong style="color: var(--cyan); font-family: var(--font-mono);">${item.name}</strong></td>
        <td><span class="badge badge-info">${item.ext}</span></td>
        <td>${item.desc}</td>
        <td>
          <button class="copy-tool-btn" data-tool="${item.name}">Sao Chép</button>
        </td>
      `;
      tbody.appendChild(tr);
    });

    // Copy tool button handler
    document.querySelectorAll('.copy-tool-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        const toolName = btn.getAttribute('data-tool');
        navigator.clipboard.writeText(toolName);
        playTone(700, 'sine', 0.1, 0.03);
        showToast(`Đã sao chép: ${toolName}`);
      });
    });
  }

  catPills.forEach(pill => {
    pill.addEventListener('click', () => {
      catPills.forEach(p => p.classList.remove('active'));
      pill.classList.add('active');
      currentCat = pill.getAttribute('data-cat');
      playTone(500, 'sine', 0.08, 0.03);
      filterAndRender();
    });
  });

  searchInput.addEventListener('input', filterAndRender);

  filterAndRender();
}

/* ==============================================================================
   8. EXPORT REPORT HANDLER
   ============================================================================== */
function initExportReport() {
  const exportBtn = document.getElementById('exportReportBtn');
  exportBtn.addEventListener('click', () => {
    playChime();
    showToast('Đang tải bản báo cáo chuyên môn Markdown...');
    
    // Create download link for BAN_DANH_GIA_CHUYEN_MON_TAN_THE_GIOI.md
    const link = document.createElement('a');
    link.href = '../BAN_DANH_GIA_CHUYEN_MON_TAN_THE_GIOI.md';
    link.download = 'BAN_DANH_GIA_CHUYEN_MON_TAN_THE_GIOI.md';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  });
}

/* ==============================================================================
   9. GLOBAL TOAST NOTIFICATION
   ============================================================================== */
let toastTimeout = null;

function showToast(message) {
  const toast = document.getElementById('appToast');
  const msgEl = toast.querySelector('.toast-msg');
  msgEl.textContent = message;

  toast.classList.add('show');

  if (toastTimeout) clearTimeout(toastTimeout);
  toastTimeout = setTimeout(() => {
    toast.classList.remove('show');
  }, 2800);
}
