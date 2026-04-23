const repo = "Nodirbek2345/Sartarosh-app";
const url = `https://api.github.com/repos/${repo}/actions/runs`;

async function check() {
    try {
        const res = await fetch(url);
        const data = await res.json();
        if (data.workflow_runs && data.workflow_runs.length > 0) {
            const run = data.workflow_runs[0];
            console.log(`Ohirgi yugurish: ${run.name} (${run.status})`);
            console.log(`Xulosa: ${run.conclusion || 'Hali kutilmoqda'}`);
            console.log(`Yaratildi: ${run.created_at}`);
            console.log(`Yangilandi: ${run.updated_at}`);
            console.log(`Commit: ${run.head_commit.message}`);
            console.log(`URL: ${run.html_url}`);
        } else {
            console.log("Hech qanday Action topilmadi.");
        }
    } catch (err) {
        console.log("Xatolik:", err);
    }
}
check();
