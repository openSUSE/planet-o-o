function toggleArticleExpand(id, showmore, showless) {
	const button = document.getElementById(`button_${id}`);
	const elementToChange = document.getElementById(`content_${id}`);
	const isExpanded = button.getAttribute('aria-expanded') === 'true';

	elementToChange.style.maxHeight = isExpanded ? "50vh" : "100%";
	button.setAttribute('aria-expanded', String(!isExpanded));
	button.innerHTML = isExpanded ? showmore : showless;

	if (isExpanded) {
		setTimeout(() => {
			button.scrollIntoView({behavior: "smooth", block: "start"});
		}, 300);
	}
}