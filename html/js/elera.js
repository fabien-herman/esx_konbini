let basket = {};
let store = "";
let player = "";
let products;

$(window).ready(function () {

	window.addEventListener('message', function (event) {
		let data = event.data;
		store = data.store;
		player = data.player;

		products = data.products || {};

		$("#catalog").empty();
		Object.values(products).forEach(function (p) {
			const info = $('<div class="info">')
				.append('<div class="title">' + p.label + '</div>')
				.append('<div class="price">' + p.price + '€</div>')
				.append('<div class="subtitle">Stock: ' + p.stock + '/' + p.max + '</div>')

			$('<div class="product" title="' + p.name + '"></div>')
				.append('<div class="icon"><img src="img/' + p.picture + '_x64.png" alt=""></div>')
				.append(info)
				.appendTo("#catalog");
		});

		refreshBasket();

		$('.product').on('click', function () {
			const name = $(this).attr("title");
			addOneItem(name);
		});

		if (data.showMenu) {
			$('div#screen').fadeIn();
			$('div.checkout').fadeIn();
		} else if (data.hideAll) {
			$('div#screen').fadeOut();
		}
	});


	document.onkeyup = function (data) {
		if (data.which == 27) {
			$.post('http://esx_konbini/escape', '{}');
		}
	};

	function addOneItem(name) {
		const product = products[name]
		if (!basket.hasOwnProperty(name)) {
			basket[name] = {label: product.label, price: product.price, qty: 1};
		} else {
			const item = basket[name];
			if (item.qty + 1 <= product.stock) {
				item.qty += 1;
			}
		}
		refreshBasket();
	}

	function removeOneItem(name) {
		if (basket.hasOwnProperty(name)) {
			const item = basket[name];
			if (item.qty > 0) {
				item.qty -= 1;
			}
			if (item.qty <= 0) {
				delete basket[name];
			}
		}
		refreshBasket();
	}

	function toMoney(number) {
		const tof = typeof number;
		if (tof === 'string') try {
			number = parseFloat(number);
		} catch {
			return 0;
		}
		else if (tof !== 'number') {
			number = 0.0;
		}
		return number.toFixed(2);
	}

	function refreshBasket() {
		$("#store").html("<b>" + store + "</b>")
		$("#items").empty();

		let gross = 0.0;

		Object.entries(basket).forEach(function ([name, item]) {

			const price = parseFloat(item.price) * parseFloat(item.qty);
			gross += price;

			$('<div class="item" about="' + name + '"></div>')
				.append('<span class="label">' + item.qty + 'x ' + item.label + '</span>')
				.append('<span class="price">' + toMoney(price) + ' €' + '</span>')
				.appendTo("#items");
		});

		const net = gross / 1.2;
		$("#net").html(toMoney(net) + ' €');
		$("#vat").html(toMoney(gross - net) + ' €');
		$("#gross").html(toMoney(gross) + ' €');
		$("#lcd").html(toMoney(gross) + ' €');

		$('.item').on('click', function () {
			const name = $(this).attr('about');
			removeOneItem(name);
		});
	}

	$('div#screen').hide();

	$('#credit_btn').on('click', function () {
		$.post('http://esx_konbini/withdrawMoney', JSON.stringify({amount: 1000}));
	});

	$('#leave_btn').on('click', function () {
		$.post('http://esx_konbini/escape', '{}');
	});


	$('.btn').on('click', function () {
		Object.entries(basket).forEach(function ([name, item]) {
			$.post('http://esx_konbini/buyItem', JSON.stringify({name: name, amount: item.qty}));
		});
		basket = {};

		refreshBasket();
	});


});
