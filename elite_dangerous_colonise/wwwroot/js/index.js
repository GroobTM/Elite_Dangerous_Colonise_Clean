var formData;
var resultsPerPage = 10;
var currentPage = 1;
var maxPages = 1;

// Countdown Events
var conn = new signalR.HubConnectionBuilder()
    .withUrl("/updateHub")
    .build();

conn.start().catch(err => console.error(err.toString()));

conn.on("SystemUpdateStarted", function () {
    document.getElementById("update_countdown").innerText = "Update in Progress";
});

conn.on("SearchBlockEnabled", function () {
    ToggleSearch(true);
    alert("The update is being cleaned up. Searching is disabled for a few minutes.")
});

conn.on("SystemUpdateComplete", function () {
    ToggleSearch(false);
    StartCountdown();
});

conn.on("SystemUpdateStatus", function (updateStatus, searchStatus) {
    if (updateStatus === "inProgress") {
        document.getElementById("update_countdown").innerText = "Update in Progress";

        if (searchStatus === "blocked") {
            ToggleSearch(true);
            alert("The update is being cleaned up. Searching is disabled for a few minutes.")
        }
    }
    else {
        StartCountdown();
    }
});

function StartCountdown() {
    if (interval) {
        clearInterval(interval);
    }

    var now = new Date();
    var target = new Date();

    target.setUTCHours(5, 0, 0, 0);

    if (now >= target) {
        target.setUTCDate(target.getUTCDate() + 1);
    }

    var interval = setInterval(function () {
        var diff = target - new Date();
        if (diff <= 0) {
            clearInterval(interval);
            document.getElementById("update_countdown").innerText = "Update in Progress";
        }
        else {
            var hours = Math.floor(diff / (1000 * 60 * 60));
            var minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60));
            var seconds = Math.floor((diff % (1000 * 60)) / 1000);
            document.getElementById("update_countdown").innerText = `Time Until Next Update: ${hours}h ${minutes}m ${seconds}s`;
        }
    }, 1000);
}

// Search Form Functions
$(document).on("click", "#clear_button", function () {
    $("#" + $(this).attr("for")).val("");
});

$("#systems_search").on("submit", function (e) {
    e.preventDefault();
    currentPage = 1;

    SetFormData();
    LoadResults();
});

// Search Resutls Functions
function CopyToClipboard(obj) {
    var text = obj.innerText;

    navigator.clipboard.writeText(text);
}

$("#next_page").on("click", function (e) {
    e.preventDefault();
    if (currentPage < maxPages) {
        currentPage++;
        LoadResults();
    }
});

$("#previous_page").on("click", function (e) {
    e.preventDefault();
    if (currentPage > 1) {
        currentPage--;
        LoadResults();
    }
});

$("#select_page_btn").on("click", function (e) {
    e.preventDefault();
    ToggleSelectPage(true);
    $("#select_page_form").find("input").focus().select();
});

$("#select_page_form").find("input").on("blur", function (e) {
    ToggleSelectPage(false);
});

$("#select_page_form").on("submit", function (e) {
    e.preventDefault();

    var value = parseInt($(this).find("input").val());

    if (!isNaN(value)) {
        value = Math.max(Math.min(value, maxPages), 1);
        if (value != currentPage) {
            currentPage = value;
            LoadResults();
        }
    }

    $("#select_page_form").find("input").blur();
    ToggleSelectPage(false);
});

$("#results_per_page").change(function () {
    currentPage = 1;
    resultsPerPage = parseInt($(this).val(), 10);

    if (isNaN(resultsPerPage)) {
        resultsPerPage = 10;
    }

    LoadResults();
})

$("#next_page").prop("disabled", true);
$("#previous_page").prop("disabled", true);
$("#select_page_btn").prop("disabled", true);
$("#results_per_page").prop("disabled", true);
$("#results_per_page_lbl").addClass("opacity-50", true);

function ToggleSelectPage(isSelecting) {
    $("#select_page_btn").toggleClass("hidden", isSelecting);
    $("#select_page_form").toggleClass("hidden", !isSelecting);
}

function ToggleSearch(isSearching) {
    $("#search")
        .prop("disabled", isSearching)
        .toggleClass("cursor-progress", isSearching)
        .toggleClass("cursor-pointer", !isSearching);
}

function SetFormData() {
    formData = new FormData(document.getElementById("systems_search"));
}

async function LoadResults() {
    ToggleSearch(true);        
    $("#loading").addClass("flex").removeClass("hidden");

    const searchParams = new URLSearchParams({
        colonisedSystem: formData.get("ColonisedSystem"),
        faction: formData.get("Faction"),
        sortOrder: formData.get("SortOrder"),
        includeClaimed: formData.get("IncludeClaimed") === "include",
        currentPage: currentPage,
        resultsPerPage: resultsPerPage
    });

    const response = await fetch(`/Index?handler=Search&${searchParams}`);

    if (!response.ok) {
        console.error("Error loading search results.")
        return;
    }

    const results = await response.json();

    if (results?.results?.length > 0) {
        FormatResults(results);
        FormatPagination(true);
    }
    else {
        FormatNoResults();
        FormatPagination(false);
    }

    $("#loading").addClass("hidden").removeClass("flex");
    ToggleSearch(false);
}

function FormatResults(results) {
    const resultsDiv = document.getElementById("results");
    var count = 0;
    var systems = results.results;
    resultsDiv.innerHTML = ``;
    maxPages = Math.ceil(results.totalCount / resultsPerPage);

    systems.forEach(system => {
        var bodiesAndRings = GetBodiesAndRings(system.bodies);

        resultsDiv.innerHTML += `
            <div id="results-heading-${system.nearbySystemID}" class="grid">
                <button type="button" class="${FormatTopBoarder(count)} flex w-full cursor-pointer items-center justify-between gap-3 border border-[#0F0F0F] bg-white p-5 text-[#0F0F0F] shadow-sm hover:bg-[#ff9305] rtl:text-right" data-accordion-target="#results-body-${system.nearbySystemID}" aria-expanded="false" aria-controls="results-body-${system.nearbySystemID}">
                    <span class="flex items-center text-[#0F0F0F]">${system.systemName}</span>
                    <svg data-accordion-icon class="h-3 w-3 shrink-0 rotate-180 transition-transform duration-200" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 10 6">
                        <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5 5 1 1 5"/>
                    </svg>
                </button>
            </div>
            
            <div id="results-body-${system.nearbySystemID}" class="hidden" aria-labelledby="results-heading-${system.nearbySystemID}">
                <div class="grid-rows-auto grid grid-cols-1 gap-y-5 border border-t-0 border-[#0F0F0F] bg-white p-5 shadow-sm lg:grid-cols-2 lg:gap-x-5 xl:gap-y-0 xl:grid-cols-4">
                    <h2 class="row-start-1 border-b border-gray-300 pb-3 text-center text-lg drop-shadow-xs lg:col-start-1 lg:text-left">Details</h2>
                    <div class="row-start-2 mt-3 lg:col-start-1">
                        <div class="grid grid-cols-2 items-end gap-x-2">
                            <h3 class="mt-3 font-bold">Name:</h3>
                            <p class="mt-3"><span data-tooltip-target ="${system.nearbySystemID}_tooltip" class="cursor-copy" onclick="CopyToClipboard(this);">${system.systemName}</span></p>
                            <h3 class="mt-3 font-bold">Coordinates:</h3>
                            <p class="mt-3">${FormatCoordinates(system.coordinates)}</p>
                            <h3 class="mt-3 font-bold">Distance to Sol:</h3>
                            <p class="mt-3">${system.distanceToSol} ly</p>
                            <h3 class="mt-3 font-bold">System Reserve:</h3>
                            <p class="mt-3">${bodiesAndRings.reserve}</p>
                            <h3 class="mt-3 font-bold">Disembarkable Bodies:</h3>
                            <p class="mt-3">${system.landableBodiesCount}</p>
                            ${FormatClaimedInfo(system)}
                            <h3 class="mt-3 font-bold">Closest Trailblazer Megaship:</h3>
                            <p class="mt-3"><a href="https://spansh.co.uk/station/${system.trailblazer.trailblazerID}" target="_blank" class="text-blue-800 underline">${system.trailblazer.trailblazerName}</a> (${system.trailblazer.distanceToTrailblazer} ly)</p>
                        </div>
                    </div>
                    <h2 class="row-start-3 border-b border-gray-300 pt-5 pb-3 text-center text-lg drop-shadow-xs lg:col-start-2 lg:row-start-1 lg:text-left lg:pt-0">Rings</h2>
                    <div class="row-start-4 mt-3 overflow-auto max-h-100 lg:col-start-2 lg:row-start-2">
                        <ul class="list-inside list-disc font-bold">
                            ${FormatRings(bodiesAndRings.ringList)}
                        </ul>
                    </div>
                    <h2 class="row-start-5 border-b border-gray-300 pt-5 pb-3 text-center text-lg drop-shadow-xs lg:col-start-1 lg:row-start-3 lg:text-left xl:pt-0 xl:col-start-3 xl:row-start-1">Notable Bodies</h2>
                    <div class="row-start-6 mt-3 overflow-auto max-h-100 lg:col-start-1 lg:row-start-4 xl:col-start-3 xl:row-start-2">
                        <ul class="list-inside list-disc">
                            ${FormatBodies(bodiesAndRings.bodyList)}
                        </ul>
                    </div>
                    <h2 class="row-start-7 border-b border-gray-300 pt-5 pb-3 text-center text-lg drop-shadow-xs lg:col-start-2 lg:row-start-3 lg:text-left xl:pt-0 xl:col-start-4 xl:row-start-1">Nearby Stations</h2>
                    <div class="row-start-8 mt-3 overflow-auto max-h-100 lg:col-start-2 lg:row-start-4 xl:col-start-4 xl:row-start-2">
                        <ul class="list-inside list-disc">
                            ${FormatColonisedSystems(system.nearbySystemID, system.colonisedSystems)}
                        </ul>
                    </div>
                    <div class="mt-5 lg:col-span-2 xl:col-span-4">
                        <a href="https://spansh.co.uk/system/${system.nearbySystemID}" target="_blank" class="text-blue-800 underline">View on Spansh</a>
                    </div>
                </div>
                <div id="${system.nearbySystemID}_tooltip" role="tooltip" class="tooltip invisible absolute z-10 inline-block rounded-lg bg-[#0F0F0F] px-3 py-2 text-sm text-[#F0F0F0] opacity-0 shadow-xs transition-opacity duration-200">
                    Click to copy.
                </div>
                ${FormatColonisedSystemTooltips(system.nearbySystemID, system.colonisedSystems)}
            </div>
        `;
        count++;
    });

    ReinitializeAccordion();
    ReinitializeTooltips();
}

function GetBodiesAndRings(inputBodies) {
    var systemReserve = "Unknown";
    var bodies = [];
    var rings = [];

    inputBodies.forEach(body => {
        if (body.reserveType != "None") {
            systemReserve = body.reserveType;
        }

        bodies.push({
            id: body.bodyID,
            name: body.bodyName,
            type: body.bodyType
        });

        body.rings?.forEach(ring => {
            var hotspots = [];

            ring.hotspots?.forEach(hotspot => {
                hotspots.push({
                    type: hotspot.hotspotType,
                    count: hotspot.hotspotCount
                });
            });

            rings.push({
                name: ring.ringName,
                type: ring.ringType,
                hotspotList: hotspots 
            });
        });
    });

    return {
        reserve: systemReserve,
        bodyList: bodies,
        ringList: rings
    };
}

function FormatTopBoarder(count) {
    if (count == 0) {
        return "rounded-t-lg border-b-1 border-t-1";
    }
    else {
        return "border-b-1 border-t-0";
    }
}

function FormatCoordinates(inputCoords) {
    return `${inputCoords.coordinateX}, ${inputCoords.coordinateY}, ${inputCoords.coordinateZ}`;
}

function FormatClaimedInfo(inputSystem) {
    if (inputSystem.lastColonisingUpdate != null) {
        const date = new Date(inputSystem.lastColonisingUpdate);
        return `
        <h3 class="mt-3 font-bold">Claim Date:</h3>
        <p class="mt-3">${date.toISOString().split("T")[0]}</p>
        `;
    }
    else {
        return "";
    }
}

function FormatRings(inputRings) {
    var ringList = ``;

    inputRings.sort((a, b) => a.name.localeCompare(b.name, undefined, { numeric: true }));

    inputRings.forEach(ring => {
        ringList += `
        <li>
            ${ring.name} (${ring.type})
            <ul class="items-center ps-7 font-normal">
                ${FormatHotspots(ring.hotspotList)}
            </ul>
        </li>
        `;
    });

    return ringList;
}

function FormatHotspots(inputHotspots) {
    var hotspotList = ``;

    inputHotspots.sort((a, b) => a.type.localeCompare(b.type, undefined, { numeric: true }));

    inputHotspots.forEach(hotspot => {
        hotspotList += `
        <li>&#10551;&nbsp;${hotspot.type}&nbsp;-&nbsp;${hotspot.count}</li>
        `;
    });

    return hotspotList;
}

function FormatBodies(inputBodies) {
    const notableTypes = ["Black Hole", "Neutron Star", "Ammonia world", "Water world", "Earth-like world"];

    var bodyList = ``;

    inputBodies.sort((a, b) => a.name.localeCompare(b.name, undefined, { numeric: true }));

    inputBodies.forEach(body => {

        if (notableTypes.includes(body.type)) {
            bodyList += `
            <li><a href="https://spansh.co.uk/body/${body.id}" target="_blank" class="font-bold text-blue-800 underline">${body.name}</a> - ${body.type}</li>
            `;
        }
    });

    return bodyList;
}

function FormatColonisedSystems(nearbySystemsID, inputColonisedSystems) {
    var systemsList = ``;

    inputColonisedSystems.sort((a, b) => a.systemName.localeCompare(b.systemName, undefined, { numeric: true }));

    inputColonisedSystems.forEach(system => {
        systemsList += `
        <li class="list-inside list-disc font-bold">
            <span data-tooltip-target="${nearbySystemsID}_${system.colonisedSystemID}_tooltip" class="cursor-copy" onclick="CopyToClipboard(this);">${system.systemName}</span>
            <ul class="items-center ps-7 font-normal">
                ${FormatStations(system.stations)}
            </ul>
        </li>
        `;
    });

    return systemsList;
}

function FormatStations(inputStations) {
    var stationList = ``;

    inputStations.sort((a, b) => {
        const factionCompare = a.factionName.localeCompare(b.factionName , undefined, { numeric: true });

        if (factionCompare !== 0) {
            return factionCompare;
        }
        else {
            return a.stationName.localeCompare(b.stationName, undefined, { numeric: true });
        }
    });

    inputStations.forEach(station => {
        stationList += `
        <li>&#10551;&nbsp;<a href="https://spansh.co.uk/station/${station.stationID}" target="_blank" class="text-blue-800 underline">${station.stationName}</a>&nbsp;-&nbsp;${station.factionName}</li>
        `;
    });

    return stationList;
}

function FormatColonisedSystemTooltips(nearbySystemsID, inputColonisedSystems) {
    var tooltipList = ``;

    inputColonisedSystems.forEach(system => {
        tooltipList += `
        <div id="${nearbySystemsID}_${system.colonisedSystemID}_tooltip" role="tooltip" class="tooltip invisible absolute z-10 inline-block rounded-lg bg-[#0F0F0F] px-3 py-2 text-sm text-[#F0F0F0] opacity-0 shadow-xs transition-opacity duration-200">
            Click to copy.
        </div>
        `;
    });

    return tooltipList;
}

function ReinitializeAccordion() {
    if (typeof window.initAccordions === 'function') {
        window.initAccordions();
    }

    $("[data-accordion-target]").on("click", function () {
        const button = $(this);
        const span = button.find("span");
        const svg = button.find("svg");

        if (button.attr("aria-expanded") === "true") {
            button.addClass("bg-[#F07B05] text-[#F0F0F0]")
                .removeClass("bg-white text-[#0F0F0F]");
            span.addClass("text-[#F0F0F0] font-bold")
                .removeClass("text-[#0F0F0F]");
            svg.addClass("text-[#F0F0F0]")
                .removeClass("text-[#0F0F0F]");
        }
        else {
            button.addClass("bg-white text-[#0F0F0F]")
                .removeClass("bg-[#F07B05] text-[#F0F0F0]");
            span.addClass("text-[#0F0F0F]")
                .removeClass("text-[#F0F0F0] font-bold");
            svg.addClass("text-[#0F0F0F]")
                .removeClass("text-[#F0F0F0]");
        }
    });
}

function ReinitializeTooltips() {
    if (typeof window.initTooltips === 'function') {
        window.initTooltips();
    }
}

function FormatPagination(results) {
    if (results) {
        $("#current_page").text("" + currentPage);
        $("#max_pages").text("" + maxPages);
        $("#results_per_page").prop("disabled", false);
        $("#results_per_page_lbl").removeClass("opacity-50");
        $("#select_page_btn").prop("disabled", false);
        $("#select_page_form").find("input")
            .val(currentPage)
            .attr("max", maxPages);

        if (currentPage <= 1) {
            $("#previous_page").prop("disabled", true);
        }
        else {
            $("#previous_page").prop("disabled", false);
        }

        if (currentPage >= maxPages) {
            $("#next_page").prop("disabled", true);
        }
        else {
            $("#next_page").prop("disabled", false);
        }
    }
    else {
        $("#current_page").text("0");
        $("#max_pages").text("0");
        $("#next_page").prop("disabled", true);
        $("#previous_page").prop("disabled", true);
        $("#select_page_btn").prop("disabled", true);
        $("#results_per_page").prop("disabled", true);
        $("#results_per_page_lbl").addClass("opacity-50");
    }
}

function FormatNoResults() {
    document.getElementById("results").innerHTML = `
    <div class="w-full">
    <h1 class="p-30 text-xl text-center">No systems found.</h1>
    </div>
    `;
}