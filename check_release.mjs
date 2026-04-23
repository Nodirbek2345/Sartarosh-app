const repo = "Nodirbek2345/Sartarosh-app";
const url = `https://api.github.com/repos/${repo}/releases/latest`;

async function check() {
    try {
        const res = await fetch(url);
        const data = await res.json();
        console.log(`Ohirgi Release: ${data.tag_name} (${data.name})`);
        console.log(`Assets soni: ${data.assets?.length || 0}`);
        if (data.assets?.length > 0) {
            console.log(`Fayl: ${data.assets[0].name} (${data.assets[0].browser_download_url})`);
        }
    } catch (err) {
        console.log("Xatolik:", err);
    }
}
check();
