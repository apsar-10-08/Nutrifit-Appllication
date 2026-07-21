import os
import json
from datetime import datetime
from automation.config import settings

def generate_html_reports(test_results):
    passed_list = [t for t in test_results if t['status'] == 'Passed']
    failed_list = [t for t in test_results if t['status'] == 'Failed']
    skipped_list = [t for t in test_results if t['status'] in ['Skipped', 'Blocked', 'Pending']]

    total_tests = len(test_results)
    passed_count = len(passed_list)
    failed_count = len(failed_list)
    skipped_count = len(skipped_list)
    success_rate = (passed_count / total_tests * 100) if total_tests > 0 else 0
    total_duration = sum(t.get('duration', 0.0) for t in test_results)
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    # Module breakdown stats
    module_stats = {}
    for t in test_results:
        m = t['category']
        if m not in module_stats:
            module_stats[m] = {'total': 0, 'passed': 0, 'failed': 0}
        module_stats[m]['total'] += 1
        if t['status'] == 'Passed':
            module_stats[m]['passed'] += 1
        elif t['status'] == 'Failed':
            module_stats[m]['failed'] += 1

    # 1. Generate execution-report.html
    rows_html = ""
    for t in test_results:
        status_color = "#10A866" if t['status'] == 'Passed' else ("#FF3333" if t['status'] == 'Failed' else "#FFAA00")
        bg_status = "#E8F8F0" if t['status'] == 'Passed' else ("#FFEEEE" if t['status'] == 'Failed' else "#FFF5E6")
        
        failure_log_html = ""
        if t['status'] == 'Failed':
            scr_path = f"../Screenshots/{t['id']}.png"
            failure_log_html = f"""
            <div class="fail-details">
                <strong>Failure Reason:</strong> {t.get('failure_reason', 'Assertion failed')}<br/>
                <a href="{scr_path}" target="_blank" class="scr-link">🖼️ View Screenshot</a>
            </div>
            """
            
        rows_html += f"""
        <tr class="test-row" data-status="{t['status']}" data-module="{t['category']}">
            <td><span class="badge-id">{t['id']}</span></td>
            <td><strong>{t['category']}</strong></td>
            <td>{t['name']}</td>
            <td><span class="badge" style="background-color: {bg_status}; color: {status_color}; font-weight: bold;">{t['status']}</span></td>
            <td style="text-align: center;">{t.get('duration', 0.0):.3f}s</td>
            <td style="text-align: center;"><span class="prio-tag prio-{t['priority'].lower()}">{t['priority']}</span></td>
        </tr>
        {"<tr><td colspan='6' class='detail-row'>" + failure_log_html + "</td></tr>" if t['status'] == 'Failed' else ""}
        """

    report_html = f"""<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>E2E Execution Report</title>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;600;800&display=swap" rel="stylesheet">
    <style>
        body {{
            font-family: 'Outfit', sans-serif;
            background-color: #F4F8F6;
            margin: 0;
            padding: 24px;
            color: #172B21;
        }}
        .header {{
            background: linear-gradient(135deg, #10A866 0%, #087A4A 100%);
            color: white;
            padding: 30px;
            border-radius: 24px;
            box-shadow: 0 10px 30px rgba(16, 168, 102, 0.15);
            margin-bottom: 24px;
        }}
        .header h1 {{ margin: 0; font-size: 28px; font-weight: 800; }}
        .header p {{ margin: 8px 0 0 0; opacity: 0.9; font-size: 14px; }}
        .stats-grid {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
            gap: 16px;
            margin-bottom: 24px;
        }}
        .stat-card {{
            background: white;
            padding: 20px;
            border-radius: 20px;
            border: 1px solid #E7EEE9;
            box-shadow: 0 4px 12px rgba(0,0,0,0.02);
            text-align: center;
        }}
        .stat-card .val {{ font-size: 26px; font-weight: 800; color: #10A866; }}
        .stat-card .lbl {{ font-size: 12px; color: #809689; margin-top: 4px; font-weight: 600; text-transform: uppercase; }}
        .filter-bar {{
            background: white;
            padding: 16px 24px;
            border-radius: 18px;
            border: 1px solid #E7EEE9;
            margin-bottom: 16px;
            display: flex;
            gap: 12px;
            align-items: center;
        }}
        .filter-btn {{
            padding: 8px 16px;
            border-radius: 12px;
            border: 1px solid #E7EEE9;
            background: #FAFCFB;
            cursor: pointer;
            font-weight: 600;
            font-size: 13px;
            transition: all 0.2s;
        }}
        .filter-btn.active, .filter-btn:hover {{
            background: #10A866;
            color: white;
            border-color: #10A866;
        }}
        table {{
            width: 100%;
            border-collapse: collapse;
            background: white;
            border-radius: 24px;
            overflow: hidden;
            box-shadow: 0 4px 20px rgba(0,0,0,0.02);
            border: 1px solid #E7EEE9;
        }}
        th {{
            background-color: #FAFCFB;
            padding: 16px;
            text-align: left;
            font-weight: 600;
            font-size: 13px;
            color: #809689;
            border-bottom: 2px solid #E7EEE9;
        }}
        td {{
            padding: 14px 16px;
            font-size: 14px;
            border-bottom: 1px solid #F1F5F2;
        }}
        .badge {{
            padding: 4px 10px;
            border-radius: 8px;
            font-size: 11px;
            text-transform: uppercase;
        }}
        .badge-id {{
            background: #FAFCFB;
            border: 1px solid #E7EEE9;
            padding: 4px 8px;
            border-radius: 8px;
            font-family: monospace;
            font-weight: 600;
        }}
        .prio-tag {{
            padding: 2px 8px;
            border-radius: 6px;
            font-size: 10px;
            font-weight: bold;
        }}
        .prio-high {{ background: #FFEBEB; color: #FF3333; }}
        .prio-medium {{ background: #FFF5E6; color: #FFAA00; }}
        .prio-low {{ background: #E6F5FF; color: #0088FF; }}
        .fail-details {{
            background: #FFF5F5;
            padding: 16px;
            border-radius: 12px;
            border-left: 4px solid #FF3333;
            margin: 4px 16px 12px 16px;
            font-size: 13px;
        }}
        .scr-link {{
            display: inline-block;
            margin-top: 8px;
            color: #FF3333;
            text-decoration: none;
            font-weight: 600;
        }}
        .scr-link:hover {{ text-decoration: underline; }}
        .detail-row {{ padding: 0; }}
    </style>
</head>
<body>
    <div class="header">
        <h1>🚀 Live GitHub Pages E2E Execution Report</h1>
        <p>Execution Date: {timestamp} | Baseline Target: {settings.BASE_URL}</p>
    </div>
    
    <div class="stats-grid">
        <div class="stat-card"><div class="val">{total_tests}</div><div class="lbl">Total Tests</div></div>
        <div class="stat-card"><div class="val" style="color:#10A866;">{passed_count}</div><div class="lbl">Passed</div></div>
        <div class="stat-card"><div class="val" style="color:#FF3333;">{failed_count}</div><div class="lbl">Failed</div></div>
        <div class="stat-card"><div class="val" style="color:#FFAA00;">{skipped_count}</div><div class="lbl">Skipped</div></div>
        <div class="stat-card"><div class="val">{success_rate:.2f}%</div><div class="lbl">Success Rate</div></div>
        <div class="stat-card"><div class="val">{total_duration:.2f}s</div><div class="lbl">Duration</div></div>
    </div>

    <div class="filter-bar">
        <strong>Filter Status:</strong>
        <button class="filter-btn active" onclick="filterStatus('all')">All</button>
        <button class="filter-btn" onclick="filterStatus('Passed')">Passed</button>
        <button class="filter-btn" onclick="filterStatus('Failed')">Failed</button>
        <button class="filter-btn" onclick="filterStatus('Skipped')">Skipped</button>
    </div>

    <table>
        <thead>
            <tr>
                <th>Test Case ID</th>
                <th>Module</th>
                <th>Description</th>
                <th>Status</th>
                <th style="text-align: center;">Duration</th>
                <th style="text-align: center;">Priority</th>
            </tr>
        </thead>
        <tbody>
            {rows_html}
        </tbody>
    </table>

    <script>
        function filterStatus(status) {{
            document.querySelectorAll('.filter-btn').forEach(btn => btn.classList.remove('active'));
            event.target.classList.add('active');
            
            document.querySelectorAll('.test-row').forEach(row => {{
                if (status === 'all' || row.getAttribute('data-status') === status) {{
                    row.style.display = '';
                    let next = row.nextElementSibling;
                    if (next && next.classList.contains('detail-row') && row.getAttribute('data-status') === 'Failed') {{
                        next.style.display = '';
                    }}
                }} else {{
                    row.style.display = 'none';
                    let next = row.nextElementSibling;
                    if (next && next.classList.contains('detail-row')) {{
                        next.style.display = 'none';
                    }}
                }}
            }});
        }}
    </script>
</body>
</html>
"""
    with open(os.path.join(settings.HTML_DIR, 'execution-report.html'), 'w', encoding='utf-8') as f:
        f.write(report_html)

    # 2. Generate dashboard.html
    modules_rows = ""
    for m, s in module_stats.items():
        rate = (s['passed'] / s['total'] * 100) if s['total'] > 0 else 0
        color_bar = "#10A866" if rate >= 95 else ("#FFAA00" if rate >= 80 else "#FF3333")
        modules_rows += f"""
        <div style="margin-bottom: 16px;">
            <div style="display: flex; justify-content: space-between; font-size: 13px; font-weight: 600; margin-bottom: 6px;">
                <span>📂 {m}</span>
                <span>{s['passed']}/{s['total']} ({rate:.1f}%)</span>
            </div>
            <div style="width: 100%; height: 8px; background: #E7EEE9; border-radius: 4px; overflow: hidden;">
                <div style="width: {rate}%; height: 100%; background: {color_bar}; border-radius: 4px;"></div>
            </div>
        </div>
        """

    dashboard_html = f"""<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>E2E Automation Dashboard</title>
    <link href="https://fonts.googleapis.com/css2?family=Outfit:wght@300;400;600;800&display=swap" rel="stylesheet">
    <style>
        body {{
            font-family: 'Outfit', sans-serif;
            background-color: #F4F8F6;
            margin: 0;
            padding: 24px;
            color: #172B21;
        }}
        .header {{
            background: linear-gradient(135deg, #10A866 0%, #087A4A 100%);
            color: white;
            padding: 30px;
            border-radius: 24px;
            box-shadow: 0 10px 30px rgba(16, 168, 102, 0.15);
            margin-bottom: 24px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }}
        .header h1 {{ margin: 0; font-size: 28px; font-weight: 800; }}
        .header p {{ margin: 8px 0 0 0; opacity: 0.9; font-size: 14px; }}
        .grid {{
            display: grid;
            grid-template-columns: 2fr 1fr;
            gap: 24px;
        }}
        .panel {{
            background: white;
            padding: 24px;
            border-radius: 24px;
            border: 1px solid #E7EEE9;
            box-shadow: 0 4px 20px rgba(0,0,0,0.02);
        }}
        .panel h2 {{ margin-top: 0; font-size: 18px; font-weight: 800; margin-bottom: 20px; color: #087A4A; border-bottom: 2px solid #E8F8F0; padding-bottom: 10px; }}
        .metrics-summary {{
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 16px;
            margin-bottom: 24px;
        }}
        .metric-box {{
            padding: 16px;
            border-radius: 16px;
            text-align: center;
            border: 1px solid #E7EEE9;
        }}
        .metric-box .num {{ font-size: 32px; font-weight: 800; }}
        .metric-box .label {{ font-size: 11px; color: #809689; font-weight: 600; text-transform: uppercase; margin-top: 4px; }}
        .donut-chart-container {{
            display: flex;
            justify-content: center;
            align-items: center;
            height: 200px;
            margin-bottom: 24px;
        }}
        .donut-chart {{
            width: 150px;
            height: 150px;
            border-radius: 50%;
            background: conic-gradient(
                #10A866 0% {success_rate:.1f}%,
                #FF3333 {success_rate:.1f}% {(success_rate + (failed_count/total_tests*100)):.1f}%,
                #FFAA00 {(success_rate + (failed_count/total_tests*100)):.1f}% 100%
            );
            display: flex;
            justify-content: center;
            align-items: center;
            position: relative;
        }}
        .donut-chart::before {{
            content: '';
            position: absolute;
            width: 100px;
            height: 100px;
            background: white;
            border-radius: 50%;
        }}
        .donut-center {{
            position: relative;
            z-index: 10;
            text-align: center;
        }}
        .donut-center .pct {{ font-size: 24px; font-weight: 800; color: #087A4A; }}
        .donut-center .lbl {{ font-size: 10px; color: #809689; text-transform: uppercase; }}
        .legend {{
            display: flex;
            justify-content: center;
            gap: 16px;
            font-size: 12px;
            font-weight: 600;
        }}
        .legend-item {{ display: flex; align-items: center; gap: 6px; }}
        .dot {{ width: 12px; height: 12px; border-radius: 50%; }}
    </style>
</head>
<body>
    <div class="header">
        <div>
            <h1>📊 Test Automation Executive Dashboard</h1>
            <p>Target: {settings.BASE_URL} | Timestamp: {timestamp}</p>
        </div>
        <div style="background: rgba(255,255,255,0.15); padding: 10px 20px; border-radius: 14px; font-weight: bold; font-size: 14px;">
            PASSED ({success_rate:.1f}%)
        </div>
    </div>

    <div class="grid">
        <div class="panel">
            <h2>📦 Module Execution Trends & Pass Rates</h2>
            {modules_rows}
        </div>
        
        <div class="panel">
            <h2>📈 Test Summary</h2>
            <div class="donut-chart-container">
                <div class="donut-chart">
                    <div class="donut-center">
                        <div class="pct">{success_rate:.1f}%</div>
                        <div class="lbl">Passed</div>
                    </div>
                </div>
            </div>
            
            <div class="legend">
                <div class="legend-item"><span class="dot" style="background:#10A866;"></span> Passed ({passed_count})</div>
                <div class="legend-item"><span class="dot" style="background:#FF3333;"></span> Failed ({failed_count})</div>
                <div class="legend-item"><span class="dot" style="background:#FFAA00;"></span> Skipped ({skipped_count})</div>
            </div>
            
            <div class="metrics-summary" style="margin-top: 24px;">
                <div class="metric-box" style="background:#E8F8F0; border-color:#80CCA8;">
                    <div class="num" style="color:#10A866;">{passed_count}</div>
                    <div class="label" style="color:#087A4A;">Passed</div>
                </div>
                <div class="metric-box" style="background:#FFF5F5; border-color:#FFAAAA;">
                    <div class="num" style="color:#FF3333;">{failed_count}</div>
                    <div class="label" style="color:#AA2222;">Failed</div>
                </div>
            </div>
        </div>
    </div>
</body>
</html>
"""
    with open(os.path.join(settings.HTML_DIR, 'dashboard.html'), 'w', encoding='utf-8') as f:
        f.write(dashboard_html)
