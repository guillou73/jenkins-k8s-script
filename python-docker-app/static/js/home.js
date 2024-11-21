//close the flashing message after 5 second



document.addEventListener('DOMContentLoaded', function(e){


//pass the data from html to modal
const modals = document.querySelectorAll(".open_modal");
const footer_modal = document.querySelector(".modal-footer")

//querying each modal overlay
modals.forEach((modal) => {
  modal.addEventListener("click", () => {
    console.log("Came inside");
    var article_id = modal.getAttribute("data-id");
    var confirm = footer_modal.querySelector("#confirm");
    if (confirm.hasAttribute("href")) {
      confirm.removeAttribute("href");
    }
    confirm.setAttribute("href", `delete/${article_id}`);
  });
});


//edit the user details

const profSave= document.querySelector('#profileSave')
const profEdit = document.querySelector('#profileEdit')
const profInput = document.querySelectorAll(".form-control")

if(profEdit!= null){
profEdit.addEventListener('click', ()=>{
    profInput.forEach((eachInput)=>{
      eachInput.removeAttribute('readonly')
    })
})

profSave.addEventListener('click', ()=>{
  profInput.forEach((eachInput)=>{
    eachInput.setAttribute('readonly', true)
  })
})
}
})