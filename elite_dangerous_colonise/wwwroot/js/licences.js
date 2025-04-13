fetch("/licences/licences.json").then(response => {
    if (!response.ok) {
        throw new Error("Failed to load licences.json");
    }
    return response.json();
}).then(licenses => {
    const table = document.querySelector("#packageLicences tbody");

    var counter = 1;
    licenses.forEach(package => {
        const row = document.createElement("tr");

        if (counter % 2) {
            row.classList.add("bg-gray-300");
        }

        row.innerHTML = `
        <td class="border-r-1 p-2">${package.PackageId}</td>
        <td class="border-r-1 p-2">${package.PackageVersion}</td>
        <td class="border-r-1 p-2"><a href="${package.PackageProjectUrl}" target="_blank" class="text-blue-800 underline">${package.PackageProjectUrl}</a></td>
        <td class="border-r-1 p-2">${package.Authors}</td>
        <td class="border-r-1 p-2">${package.License}</td>
        <td class="border-r-1 p-2"><a href="${package.LicenseUrl}" target="_blank" class="text-blue-800 underline">${package.LicenseUrl}</a></td>
        `;

        table.appendChild(row);

        counter++;
    });
});