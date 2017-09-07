client = algoliasearch "N411KW7TFO", "7f9383b180c33541ff30b22f3912a368"
helper = algoliasearchHelper client, "restaurants", {"facets" : ['food_type', 'payment_options', 'dining_style', 'price_range']}
UserPosition = null

`// Returns a function, that, as long as it continues to be invoked, will not
// be triggered. The function will be called after it stops being called for
// N milliseconds. If 'immediate' is passed, trigger the function on the
// leading edge, instead of the trailing.
function debounce(func, wait, immediate) {
	var timeout;
	return function() {
		var context = this, args = arguments;
		var later = function() {
			timeout = null;
			if (!immediate) func.apply(context, args);
		};
		var callNow = immediate && !timeout;
		clearTimeout(timeout);
		timeout = setTimeout(later, wait);
		if (callNow) func.apply(context, args);
	};
};` 

helper.on "result", (content)->
	renderHits content
	renderFacets content
	renderPagination content

computeRatingClass = (rating)->
	rating = (Math.round(rating*2)/2).toFixed(1)
	intValue = parseInt rating
	remainder = rating - intValue
	if remainder == .5
		return "note-#{intValue}5"
	return "note-#{intValue}"

computeReviewsText = (reviews)->
	if reviews == 1
		return "review"
	return "reviews"

renderFacets = (content)->
	$ "#cuisine-facet"
		.html ()->
			$.map content.getFacetValues('food_type'), (facet)->
				if facet.isRefined
					className = "active"
				else 
					className = ""
				return "<li class='row align-middle #{className}' data-value='#{facet.name}'><p class='columns small-8'>#{facet.name}</p> <span class='columns small-4 align-left'>#{facet.count}</span></li>"
	$ "#payment-facet"
		.html ()->
			$.map content.getFacetValues('payment_options'), (facet)->
				if facet.isRefined
					className = "active"
				else 
					className = ""
				return "<li class='row align-middle #{className}' data-value='#{facet.name}'><p class='columns small-8'>#{facet.name}</p> <span class='columns small-4 align-left'>#{facet.count}</span></li>"
	$ "#price-facet"
		.html ()->
			$.map content.getFacetValues('price_range'), (facet)->
				if facet.isRefined
					className = "active"
				else 
					className = ""
				return "<li class='row align-middle #{className}' data-value='#{facet.name}'><p class='columns small-8'>#{facet.name}</p> <span class='columns small-4 align-left'>#{facet.count}</span></li>"

renderPagination = (content)->
	text = ""
	for i in [0..(content.nbPages - 1)]
		className = ""
		if i == content.page
			className = 'active'
		if content.nbPages > 10
			if i < 2 || i > content.nbPages - 3
				text += "<button class='paginator #{className}' data-value='#{i}'> #{i+1} </button>"
			else if i % 10 == 9
				text += "<button class='paginator #{className}' data-value='#{i}'> #{i+1} </button>"
			else if i >= content.page - 1 && i <= content.page + 1
				text += "<button class='paginator #{className}' data-value='#{i}'> #{i+1} </button>"
		else 
			text += "<button class='paginator #{className}' data-value='#{i}'> #{i+1} </button>"
	$ "#pagination"
		.html text

renderHits = (content)->
	console.log content
	if content.nbHits == 1
		textResults = content.nbHits + " result"
	else
		textResults = content.nbHits + " results"
	$ '#hits'
		.html textResults
	$ '#processingTime'
		.html content.processingTimeMS / 1000
	if content.nbHits == 0
		$ "#results-expander"
			.addClass "hide"
		$ "#results"
			.html ()->
				"<div class='no-resuls columns small-12 medium-6 medium-offset-3 text-center'><h2>There is nothing there :'(</h2><p>Looks like you\'ve been too ambitious ;). Try removing some filters or looking for something else…</p></div>"
	else 
		$ "#results-expander"
			.removeClass "hide"
		$ '#results'
			.html ()->
				$.map content.hits, (hit)->
					ratingClass = computeRatingClass(hit.stars_count)
					reviewsText = computeReviewsText(hit.reviews_count)
					return "<div class='restaurant-card row columns small-12 large-10'><a href='#{hit.reserve_url}' target='_blank'><div class='columns restaurant-picture'><img src='#{hit.image_url}' /></div><div class='columns restaurant-content row'><h1>#{hit._highlightResult.name.value}</h1><div class='row columns small-12 restaurant-meta'><div class='restaurant-rating columns'><span class='restaurant-note'>#{hit.stars_count}</span> <div class='rating #{ratingClass}'></div></div><div class='restaurant-reviews'>(#{hit.reviews_count} #{reviewsText})</div></div><div class='row columns small-12 restaurant-description'>#{hit._highlightResult.food_type.value} | #{hit._highlightResult.neighborhood.value} | #{hit.price_range}</div></div></a></div>";

geolocUser = debounce ()->
	navigator.permissions.query {"name":"geolocation"}
		.then (permission)->
			if permission.state == "prompt"
				$ "#geo-tooltip"
					.removeClass "hide"
	navigator.geolocation.getCurrentPosition (position)->
		UserPosition = "".concat position.coords.latitude, ",", position.coords.longitude
		$ "input[type=search]"
			.trigger "search"
		if !$('#geo-tooltip').hasClass("hide")
			$ "#geo-tooltip"
				.addClass "hide"
	, ()->
		$ "#geo-tooltip"
				.addClass "hide"
, 500

$ document
	.on "keyup search", "input[type=search]", (e)->
		helper.setQuery e.target.value
		helper.setQueryParameter "aroundLatLngViaIP", false
		if navigator.geolocation
			navigator.permissions.query {"name":"geolocation"}
				.then (permission)->
					if permission.state == "granted"
						navigator.geolocation.getCurrentPosition (position)->
							UserPosition = "".concat position.coords.latitude, ",", position.coords.longitude
							if e.type == "search"
								helper.setQueryParameter "aroundLatLng", UserPosition
								helper.search()
					else 
						if e.type == "keyup"
							geolocUser()
		if UserPosition != null
			helper.setQueryParameter "aroundLatLng", UserPosition
		helper.search()

$ document
	.on "click", ".facet-list li", (e)->
		updatedFacet = $ e.target
			.parents '.facet-list'
			.data 'facet'
		if $(e.target).is('[data-value]')
			facetValue = $ e.target
				.data 'value'
		else
			facetValue = $ e.target
				.parents 'li'
				.data 'value'
		if ['food_type', 'payment_options', 'price_range'].indexOf(updatedFacet) != -1
			helper.toggleFacetRefinement updatedFacet, facetValue
				.search()
		if updatedFacet == "rating"
			removeAllNumericalFilters = false
			if $("#rating-facet .active").data("value") == facetValue
				removeAllNumericalFilters = true
			$ e.target
				.parents '.facet-list'
				.find 'li'
				.removeClass 'active'
			helper.removeNumericRefinement "stars_count"
			if removeAllNumericalFilters == false
				helper.addNumericRefinement "stars_count", '>=', facetValue
				$ e.target
					.parents 'li'
					.addClass 'active'
			helper.search()

$ document
	.on "click", "#results-expander .expando-button", (e)->
		$ "#results"
			.toggleClass "expanded"
		if $("#results").hasClass "expanded"
			$ "#pagination"
				.removeClass "hide"
			$ e.target
				.html "Show fewer results"
		else
			$ "#pagination"
				.addClass "hide"
			$ e.target
				.html "Show more"
			helper.setPage 0
			helper.search()

$ document
	.on "click", ".paginator", (e)->
		helper.setPage $(e.target).data "value"
		helper.search()

$ "input[type=search]"
	.trigger "search"

