document
  .getElementById("toggle_components_button")
  .addEventListener("click", function () {
    const tableEl = document.getElementById("components_table");
    tableEl.classList.toggle("hidden");
  });
