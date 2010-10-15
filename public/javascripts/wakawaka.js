
function reload_project_list() {
  $('#project_list').load("/projects");
  if ($("td:contains('Processing message')").next().text().match(/Processing/)){
    // Check every second
    window.setTimeout(function() {
      reload_project_list();
    }, 1000);
  }
}

$("a.delete_project").click( function(element) {
  remove_project(element.href);
  return false;
});

function remove_project(url){
  $.get(url, function (){
    reload_project_list();
  });
}
