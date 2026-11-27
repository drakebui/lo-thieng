class_name GuideBook
extends RefCounted


static func get_opening_context_steps() -> Array[Dictionary]:
	return [
		{
			"type": "narration",
			"title": "Lời dẫn",
			"body": "Lò Thiêng là vùng đất của lửa, quặng và những món nợ cũ. "
				+ "Trong thời đại hỗn loạn, một thợ rèn sống sót nhờ tay nghề "
				+ "và những giao kèo khó nuốt.",
			"speaker": "",
			"bg": "",
			"portrait": "",
		},
		{
			"type": "narration",
			"title": "Lời dẫn",
			"body": "Ngươi vừa đặt chân tới thị trấn Tây Hương, nơi tiếng búa rèn "
				+ "có thể mở cửa làm ăn, hoặc kéo thêm rắc rối vào lò.",
			"speaker": "",
			"bg": "",
			"portrait": "",
		},
		{
			"type": "narration",
			"title": "Lời dẫn",
			"body": "Không tiền, không chỗ ở, không ai chống lưng. Thứ duy nhất "
				+ "ngươi còn có là đôi tay và một cơ hội mượn tạm.",
			"speaker": "",
			"bg": "",
			"portrait": "",
		},
		{
			"type": "scene_card",
			"title": "Tây Hương — Ngày đầu tiên",
			"body": "Một cánh cửa mở...",
			"speaker": "",
			"bg": "",
			"portrait": "",
		},
	]


static func get_ba_trum_intro_steps() -> Array[Dictionary]:
	return [
		{
			"type": "narration",
			"title": "Lò Không Khóa",
			"body": "Mưa tro rơi rất nhẹ. Người Giữ Lò đẩy cửa xưởng cũ — "
				+ "cửa mở ra không cần chìa khóa.",
			"speaker": "",
			"bg": "",
			"portrait": "",
		},
		{
			"type": "dialogue",
			"title": "Người Giữ Lò",
			"body": "...Ai đó đã vào trước.",
			"speaker": "Người Giữ Lò",
			"bg": "",
			"portrait": "",
		},
		{
			"type": "narration",
			"title": "Bên trong lò",
			"body": "Có đe, có lò, có phôi sắt nằm dở dang. Không có mùi bỏ hoang. "
				+ "Có mùi than cũ, sắt lạnh, và thứ gì đó như lời hứa để lâu quá.",
			"speaker": "",
			"bg": "",
			"portrait": "",
		},
		{
			"type": "dialogue",
			"title": "Bà Trùm Hắc Nguyệt",
			"body": "Cảm động đấy, bé mèo. Nhưng cảm động không trả được lãi.",
			"speaker": "Bà Trùm Hắc Nguyệt",
			"bg": "",
			"portrait": "",
		},
		{
			"type": "dialogue",
			"title": "Chủ nợ",
			"body": "Ta đợi ngươi từ sáng sớm. Người ta nói Lò Thiêng có chủ mới về. "
				+ "Ta nói: hãy đợi xem tay chủ mới có chai không đã.",
			"speaker": "Bà Trùm Hắc Nguyệt",
			"bg": "",
			"portrait": "",
		},
		{
			"type": "dialogue",
			"title": "Cơn Nợ đầu tiên",
			"body": "Hắc Nguyệt. Chủ nợ duy nhất của cái xưởng ngươi vừa bước vào. "
				+ "Cơn Nợ đầu tiên: 3,000G. Ngày thứ 4, ta lấy đủ.",
			"speaker": "Bà Trùm Hắc Nguyệt",
			"bg": "",
			"portrait": "",
		},
		{
			"type": "dialogue",
			"title": "Bà Trùm rời đi",
			"body": "Và đừng để lò tắt. Lần cuối nó tắt... mất cả đời người "
				+ "mới gọi nó dậy lại được.",
			"speaker": "Bà Trùm Hắc Nguyệt",
			"bg": "",
			"portrait": "",
		},
		{
			"type": "dialogue",
			"title": "Bắt đầu",
			"body": "...Ừ. Vậy thì bắt đầu thôi.",
			"speaker": "Người Giữ Lò",
			"bg": "",
			"portrait": "",
		},
	]


static func get_ntn_day1_dialogue() -> Array[Dictionary]:
	return [
		{
			"type": "dialogue",
			"speaker": "Người Thu Nợ",
			"title": "Người Thu Nợ — Chợ Ngoài",
			"body": "Tay thu nợ Gà Trống Đen bước vào từ cửa xưởng, ôm cuộn sổ khế ước trong tay.\n"
				+ "\"Thợ mới à. Đúng giờ đấy — bà Trùm nói ngươi ổn.\"",
		},
		{
			"type": "dialogue",
			"speaker": "Người Thu Nợ",
			"title": "Tự giới thiệu",
			"body": "\"Ta là người thu nợ phụ trách Chợ Ngoài. Không phải người xấu —\n"
				+ "ta chỉ làm đúng việc của mình. Ngươi đủ tiền thì ta đi thẳng.\"",
		},
		{
			"type": "dialogue",
			"speaker": "Người Thu Nợ",
			"title": "Khoản C1 — Tiền mặt bằng",
			"body": "\"3,000G. Tiền thuê mảnh đất và cái lò ngươi đang đứng trong đó.\n"
				+ "Bà Trùm không tính lãi — chỉ cần đúng số, đúng hạn.\"",
		},
		{
			"type": "dialogue",
			"speaker": "Người Thu Nợ",
			"title": "Hạn chót",
			"body": "\"Ngày thứ 4, buổi chiều. Ta sẽ quay lại đây.\n"
				+ "Trả đủ → xong việc. Thiếu → ta ghi sổ, tiền phạt tăng 300G.\"",
		},
		{
			"type": "dialogue",
			"speaker": "Người Thu Nợ",
			"title": "Nếu trễ hơn",
			"body": "\"Trễ 2 đợt liên tiếp, bà Trùm sẽ trực tiếp xử lý.\n"
				+ "Ta không muốn ngươi gặp bà trong tình huống đó.\"",
		},
		{
			"type": "dialogue",
			"speaker": "Người Thu Nợ",
			"title": "Lời khuyên",
			"body": "\"Rèn đồ bán sớm. Đừng giữ vũ khí tốt trong kho — khách trả tiền\n"
				+ "mới là vàng thật. Vũ khí trong kho chỉ là vàng trên giấy.\"",
		},
		{
			"type": "dialogue",
			"speaker": "Người Thu Nợ",
			"title": "Trước khi ra về",
			"body": "\"Ngươi có thể trả sớm bất cứ lúc nào trong màn tổng kết ban đêm.\n"
				+ "Ta không cần ngươi chờ đến ngày 4 — sớm càng tốt cho cả hai.\"",
		},
		{
			"type": "dialogue",
			"speaker": "Người Thu Nợ",
			"title": "Ra về",
			"body": "Tay thu nợ gật đầu ngắn, xoay người bước ra khỏi cửa.\n"
				+ "\"3,000G. Ngày 4. Đừng quên.\"\n"
				+ "Popup thông tin khoản nợ sẽ hiện tiếp theo.",
		},
	]


static func get_tay_sai_rung_dialogue() -> Array[Dictionary]:
	# Full-game only: demo 4 ngày chỉ tease C2, không spawn agent C2.
	return [
		{
			"type": "dialogue",
			"speaker": "Tay Sai Rừng",
			"title": "Người đứng ở lối rừng",
			"body": "Bà Trùm sai ta đến. Ta không vào lò, cũng không uống trà.",
		},
		{
			"type": "dialogue",
			"speaker": "Tay Sai Rừng",
			"title": "Khoản C2",
			"body": "8,000G. Tiền dẫn đường vào rừng. Không phải tiền mua rừng.",
		},
		{
			"type": "dialogue",
			"speaker": "Tay Sai Rừng",
			"title": "Đường vào",
			"body": "Rừng Trăm Hồn có nhiều lối. Lối còn sống mà đi ra thì ít hơn.",
		},
		{
			"type": "dialogue",
			"speaker": "Tay Sai Rừng",
			"title": "Hạn ngày 12",
			"body": "Ngày 12 là hạn. Trước ngày đó, vàng im lặng. Sau ngày đó, sổ nói.",
		},
		{
			"type": "dialogue",
			"speaker": "Tay Sai Rừng",
			"title": "Nếu trễ",
			"body": "Nếu ngươi trễ, sẽ có thứ gì đó xấu xảy ra. Ta không cần nói rõ.",
		},
		{
			"type": "dialogue",
			"speaker": "Tay Sai Rừng",
			"title": "Rời đi",
			"body": "Tối nào có đủ tiền thì trả. Ta chỉ cần đường được mở đúng hạn.",
		},
	]


static func get_thuong_nhan_dialogue() -> Array[Dictionary]:
	# Full-game only: demo 4 ngày không chạy C3.
	return [
		{
			"type": "dialogue",
			"speaker": "Thương Nhân Sa Mạc",
			"title": "Vị khách lịch sự",
			"body": "Chào thợ rèn. Ta không vào nhiều lần — thương nhân không có thời gian.",
		},
		{
			"type": "dialogue",
			"speaker": "Thương Nhân Sa Mạc",
			"title": "Thuế giữa mùa",
			"body": "24,000G. Gọi là thuế — nhưng ta gọi là phí bảo hộ cho ngọn lửa của ngươi.",
		},
		{
			"type": "dialogue",
			"speaker": "Thương Nhân Sa Mạc",
			"title": "Lý do",
			"body": "Sa mạc xa, nhưng tin tức về một lò rèn mới thì đến nhanh.\n"
				+ "Bà Trùm Hắc Nguyệt nhờ ta ghé qua — ta chỉ thu đúng số, không thêm.",
		},
		{
			"type": "dialogue",
			"speaker": "Thương Nhân Sa Mạc",
			"title": "Hạn ngày 28",
			"body": "Ngày 28. Ta sẽ quay lại đúng một lần.\n"
				+ "Nếu không đủ, ta ghi sổ — và bà Trùm nhận báo cáo vào sáng hôm sau.",
		},
		{
			"type": "dialogue",
			"speaker": "Thương Nhân Sa Mạc",
			"title": "Nếu trễ",
			"body": "Phạt 2,400G. Nhỏ với ta, nhưng với ngươi thì...\n"
				+ "Ta không cần nói rõ hậu quả — ngươi đã biết sau C1 và C2 rồi.",
		},
		{
			"type": "dialogue",
			"speaker": "Thương Nhân Sa Mạc",
			"title": "Ra đi",
			"body": "Tiền mặt, đủ số. Ngày 28.\n"
				+ "Ta không thích phức tạp — và ta nghĩ ngươi cũng vậy.",
		},
	]


static func get_ba_trum_c4_dialogue() -> Array[Dictionary]:
	# Full-game only: Bà Trùm xuất hiện trực tiếp tại lò ngày 29, đây là đợt đòi cuối.
	return [
		{
			"type": "narration",
			"speaker": "",
			"title": "Ngày 29 — Người chủ thật sự",
			"body": "Người đàn bà đi vào lò không gõ cửa. "
				+ "Không cần gõ — đây là nhà của bà.",
		},
		{
			"type": "dialogue",
			"speaker": "Bà Trùm Hắc Nguyệt",
			"title": "Lần này ta đến",
			"body": "Ta không phái tay sai nữa. Khoản cuối, ta muốn nhìn mặt người trả.",
		},
		{
			"type": "dialogue",
			"speaker": "Bà Trùm Hắc Nguyệt",
			"title": "Số tiền",
			"body": "65,000G. Đó là nợ gốc khi ngươi nhận lò từ ta.\n"
				+ "C1, C2, C3 là lãi và phí bảo hộ. Đây mới là gốc.",
		},
		{
			"type": "dialogue",
			"speaker": "Bà Trùm Hắc Nguyệt",
			"title": "Hạn chót",
			"body": "Ngày 52. Đó là ngày ta trao giấy chứng nhận lò cho ngươi, hoặc thu lại.",
		},
		{
			"type": "dialogue",
			"speaker": "Bà Trùm Hắc Nguyệt",
			"title": "Nếu trễ",
			"body": "Phạt 6,500G. Và mỗi ngày sau đó sẽ có khách đặc biệt vào tiệm ngươi.\n"
				+ "Không mua gì — chỉ nhắc ta vẫn đang chờ.",
		},
		{
			"type": "dialogue",
			"speaker": "Bà Trùm Hắc Nguyệt",
			"title": "Ra đi",
			"body": "Ngươi đã sống sót qua ba khoản trước. "
				+ "Ta tò mò xem ngươi có qua được khoản này không.",
		},
	]


static func get_day0_intro_steps() -> Array[Dictionary]:
	return [
		{
			"title": "Ngày 0 — Học việc",
			"body": "Hôm nay là ngày hướng dẫn. Bạn sẽ học đủ vòng lặp: "
				+ "vào Lò Rèn, tạo một vũ khí, bày lên kệ, mở tiệm và bán hàng.",
		},
		{
			"title": "Sau ngày 0",
			"body": "Từ ngày 1 khoản nợ 3,000G bắt đầu được tính hạn.\n"
				+ "Hoàn thành bài hướng dẫn trước để ngày 1 không bị rối.",
		},
		{
			"title": "Khám phá vùng đất",
			"body": "Sau ngày 0, cửa Khám Phá bên trái sẽ mở để bạn chọn Vùng Đất.\n"
				+ "Mỗi chuyến tốn thể lực và cần vũ khí, nên hãy giữ Búa Sắt Cũ "
				+ "để có đồ đi đường.",
		},
	]


static func get_explore_steps() -> Array[Dictionary]:
	return [
		{
			"title": "Đi khám phá",
			"body": "Cửa Khám Phá nằm bên trái xưởng. Vào đó để chọn vùng đất "
				+ "và bắt đầu chuyến đi lấy vật liệu.",
		},
		{
			"title": "Chọn vùng",
			"body": "Mỗi vùng có chi phí thể lực riêng. Nếu không đủ thể lực, "
				+ "hãy nghỉ sang ngày mới rồi quay lại.",
		},
		{
			"title": "Trang bị chiến đấu",
			"body": "Trước khi vào vùng, chọn vũ khí mang theo trong loadout.\n"
				+ "Đừng bán Búa Sắt Cũ ở ngày 0-1: đó là vũ khí giữ đường khi khám phá.",
		},
		{
			"title": "Trong vùng đất",
			"body": "Quái đi tuần có thể kéo bạn vào combat. Thắng combat sẽ đưa "
				+ "loot vào Túi Khám Phá; bấm B để kiểm tra túi.",
		},
		{
			"title": "Rời vùng",
			"body": "Đi về lối ra bên trái và nhấn E, hoặc nhấn ESC để quay về xưởng.\n"
				+ "Vật liệu trong Túi Khám Phá sẽ được chuyển vào kho.",
		},
	]


static func get_forge_steps() -> Array[Dictionary]:
	return [
		{
			"title": "Rèn vũ khí",
			"body": "Rèn có 3 phase: Nung giữ nhiệt, Rèn Búa canh nhịp, "
				+ "Tôi Luyện chọn nguyên tố để chốt hiệu ứng.",
		},
		{
			"title": "Phase 1 — Nung",
			"body": "Giữ nhiệt trong vùng đẹp. Lạnh quá thì vũ khí yếu, "
				+ "quá lửa thì dễ hỏng nhịp rèn.",
		},
		{
			"title": "Phase 2 — Rèn Búa",
			"body": "Canh nhịp búa vào vùng tốt hoặc hoàn hảo. "
				+ "Điểm phase này quyết định prefix và giá trị vũ khí.",
		},
		{
			"title": "Phase 3 — Tôi Luyện",
			"body": "Chọn nguyên tố tôi luyện để chốt hiệu ứng cuối. "
				+ "Sau phase này vũ khí mới được tạo ra.",
		},
	]


static func get_shop_steps() -> Array[Dictionary]:
	return [
		{
			"title": "Trước khi mở tiệm",
			"body": "Vào Tiệm, tới gần kệ và nhấn E để bày vũ khí.\n"
				+ "Khi ít nhất một kệ có hàng, nhấn 'Mở Cửa Hàng'.",
		},
		{
			"title": "Bán hàng",
			"body": "Trong Tiệm, bày vũ khí lên kệ rồi mở cửa.\n"
				+ "Khách tự chọn hàng và tới quầy để bargain.",
		},
		{
			"title": "Bargain",
			"body": "Bạn có thể bán theo giá khách, đề xuất giá mới, đổi hàng hoặc từ chối.\n"
				+ "Giá quá cao làm khách mất kiên nhẫn và bỏ đi.",
		},
	]


static func get_day1_post_ntn_steps() -> Array[Dictionary]:
	return [
		{
			"title": "Vòng lặp 4 giai đoạn",
			"body": "Mỗi ngày có 4 giai đoạn: Sáng → Trưa → Chiều → Đêm.\n"
				+ "Vào Lò Rèn đẩy ngày sang Trưa, vào Tiệm đẩy sang Chiều, "
				+ "ngủ đêm kết thúc ngày và hồi thể lực.",
		},
		{
			"title": "Sáng — Khám phá lấy vật liệu",
			"body": "Cửa bên trái dẫn ra Vùng Đất. Chiến đấu với quái để thu vật liệu.\n"
				+ "Mỗi chuyến tốn thể lực — thể lực hồi đầy sau khi nghỉ đêm.",
		},
		{
			"title": "Trưa — Rèn vũ khí",
			"body": "Vào Lò Rèn biến vật liệu thành vũ khí qua 3 phase: "
				+ "Nung → Rèn Búa → Tôi Luyện.\n"
				+ "Vũ khí tốt hơn sẽ bán được giá cao hơn.",
		},
		{
			"title": "Chiều — Mở tiệm bán hàng",
			"body": "Vào Tiệm bày vũ khí lên kệ rồi mở cửa. "
				+ "Mặc cả cho hợp lý — khách chỉ kiên nhẫn vài lần trước khi bỏ đi.",
		},
		{
			"title": "Đêm — Nghỉ và lưu game",
			"body": "Vào khu Nghỉ Ngơi (góc phải trên) để kết thúc ngày.\n"
				+ "Game chỉ lưu được vào ban đêm — đừng quên bấm lưu trước khi thoát.",
		},
		{
			"title": "Mục tiêu 4 ngày",
			"body": "Kiếm đủ 3,000G trước khi Người Thu Nợ quay lại ở ngày 4.\n"
				+ "Có thể trả nợ tại màn tổng kết ban đêm — hoặc ngay khi hắn đến.",
		},
	]


static func get_day_loop_steps() -> Array[Dictionary]:
	return [
		{
			"title": "Vòng lặp ngày",
			"body": "Mỗi ngày xoay quanh 3 việc chính: khám phá lấy vật liệu, "
				+ "rèn vũ khí, rồi bán để kiếm vàng.",
		},
		{
			"title": "Thể lực và thời gian",
			"body": "Khám phá tiêu hao thể lực. Rèn và bán hàng đẩy vòng ngày "
				+ "tiến tới ban đêm, nơi bạn tổng kết và nghỉ.",
		},
	]


static func get_debt_steps() -> Array[Dictionary]:
	return [
		{
			"title": "Khoản nợ",
			"body": "Từ ngày 1, mục tiêu là tích đủ 3,000G trước hạn ngày 4.\n"
				+ "Dùng Guide Book bất cứ lúc nào nếu quên bước tiếp theo.",
		},
	]


static func get_sections() -> Array[Dictionary]:
	return [
		{
			"title": "Vòng lặp ngày",
			"steps": get_day_loop_steps(),
		},
		{
			"title": "Đi khám phá",
			"steps": get_explore_steps(),
		},
		{
			"title": "Rèn vũ khí",
			"steps": get_forge_steps(),
		},
		{
			"title": "Bán hàng",
			"steps": get_shop_steps(),
		},
		{
			"title": "Khoản nợ",
			"steps": get_debt_steps(),
		},
	]


static func get_steps() -> Array[Dictionary]:
	var all_steps: Array[Dictionary] = []
	for section: Dictionary in get_sections():
		var steps: Array = section.get("steps", [])
		for step: Dictionary in steps:
			all_steps.append(step)
	return all_steps


static func get_day0_forge_steps() -> Array[Dictionary]:
	return [
		{
			"type": "dialogue",
			"speaker": "Cục Than",
			"title": "Mèo xám trên xà nhà",
			"body": "Nung đủ nóng rồi mới búa. Ngươi biết không?",
		},
		{
			"type": "dialogue",
			"speaker": "Cục Than",
			"title": "Cục Than",
			"body": "Ta không biết rèn. Ta biết xem người rèn bị hỏng chỗ nào. "
				+ "Hai mươi năm ngồi đây, ta đã xem đủ rồi.",
		},
		{
			"title": "Ba phase rèn",
			"body": "Mỗi vũ khí đi qua 3 bước: Nung → Rèn Búa → Tôi Luyện.\n"
				+ "Làm tốt từng bước sẽ tăng chất lượng, chỉ số và giá bán.",
		},
		{
			"title": "Phase 1 — Nung",
			"body": "Giữ nhiệt trong vùng đẹp. Lạnh quá thì vũ khí yếu, "
				+ "quá lửa thì dễ hỏng nhịp rèn.",
		},
		{
			"title": "Phase 2 — Rèn Búa",
			"body": "Canh nhịp búa vào vùng tốt hoặc hoàn hảo. "
				+ "Điểm phase này quyết định prefix và giá trị vũ khí.",
		},
		{
			"title": "Phase 3 — Tôi Luyện",
			"body": "Chọn nguyên tố tôi luyện để chốt hiệu ứng cuối. "
				+ "Sau phase này vũ khí mới được tạo ra.",
		},
	]


static func get_first_forge_complete_steps() -> Array[Dictionary]:
	return [
		{
			"type": "dialogue",
			"speaker": "Người Giữ Lò",
			"title": "Lò thở lần đầu",
			"body": "Sao tay mình lại... cảm thấy nặng hơn?",
		},
		{
			"type": "narration",
			"title": "Lửa trong lò",
			"body": "Từ lòng lò, ánh lửa nhỏ bật lên một lần nữa, mạnh hơn một chút.",
		},
		{
			"type": "dialogue",
			"speaker": "Người Giữ Lò",
			"title": "Thanh vũ khí đầu tiên",
			"body": "Ông bà làm được thứ này suốt mấy đời. Mình chỉ cần... "
				+ "không làm mọi thứ tệ thêm.",
		},
		{
			"type": "dialogue",
			"speaker": "Người Giữ Lò",
			"title": "Điều làm được",
			"body": "Ít ra đây là điều mình có thể làm được.",
		},
	]


static func get_day0_shop_phase_steps() -> Array[Dictionary]:
	return [
		{
			"title": "Trước khi mở tiệm",
			"body": "Vào Tiệm, tới gần kệ và nhấn E để bày vũ khí.\n"
				+ "Khi ít nhất một kệ có hàng, nhấn 'Mở Cửa Hàng'.",
		},
		{
			"title": "Khách và bargain",
			"body": "Khách sẽ tự chọn vũ khí trên kệ rồi tới quầy.\n"
				+ "Bạn sẽ được chọn bán theo giá khách, đề xuất giá mới, "
				+ "đổi hàng hoặc từ chối.",
		},
	]


static func get_day0_shop_hint_steps() -> Array[Dictionary]:
	return [
		{
			"title": "Bán món đầu tiên",
			"body": "Vũ khí đã xong! Vào Tiệm (ô bên phải), "
				+ "kéo vũ khí lên kệ rồi nhấn 'Mở Cửa'.\n"
				+ "Khách sẽ vào tự động — đàm phán giá rồi chốt đơn.",
		},
	]


static func get_day2_intro_steps() -> Array[Dictionary]:
	return [
		{
			"title": "Ngày 2 — Tự do",
			"body": "Bạn tự quyết hôm nay làm gì:\n"
				+ "• Rèn thêm vũ khí tốt hơn → bán giá cao hơn\n"
				+ "• Vào Vùng Đất khám phá để kiếm vật liệu hiếm\n"
				+ "Mục tiêu: tích đủ 3,000G trước ngày 4.",
		},
	]


static func get_day3_intro_steps(has_met_co_long_gio: bool) -> Array[Dictionary]:
	var body := "Có người đang chờ ở Đồng Mây Trắng.\n" \
		+ "Nếu khám phá vùng đất hôm nay, hãy tìm tảng đá nhìn ra cánh đồng."
	if has_met_co_long_gio:
		body = "Hôm qua bạn đã gặp Cô Lộng Gió — nàng sẽ còn trở lại " \
			+ "khi bạn rèn được thứ đúng với người cầm."
	return [{"title": "Ngày 3 — Cô Lộng Gió", "body": body}]


static func get_co_long_gio_first_dialogue() -> Array[Dictionary]:
	return [
		{
			"type": "dialogue",
			"speaker": "Cô Lộng Gió",
			"title": "Trên tảng đá",
			"body": "Thợ rèn Lò Thiêng. Nghe nói lò mở lại. Mình đợi lâu rồi.",
		},
		{
			"type": "dialogue",
			"speaker": "Người Giữ Lò",
			"title": "Người giữ Đồng Mây",
			"body": "Cô là...?",
		},
		{
			"type": "dialogue",
			"speaker": "Cô Lộng Gió",
			"title": "Lộng Gió",
			"body": "Lộng Gió. Người giữ Đồng Mây. Mình có Di Vật ngươi cần. Nhưng...",
		},
		{
			"type": "dialogue",
			"speaker": "Cô Lộng Gió",
			"title": "Thứ đúng nhất",
			"body": "Mình không trao cho ai chưa chứng minh được họ hiểu rèn là gì. "
				+ "Rèn cho mình một thứ. Không phải thứ mạnh nhất. Không phải thứ đắt nhất. "
				+ "Thứ đúng nhất.",
		},
		{
			"type": "dialogue",
			"speaker": "Người Giữ Lò",
			"title": "Nhu cầu thật",
			"body": "Thứ đúng nhất là gì? Cô dùng để làm gì?",
		},
		{
			"type": "dialogue",
			"speaker": "Cô Lộng Gió",
			"title": "Vũ khí để còn ở đây",
			"body": "Mình chạy nhiều. Băng cánh đồng, leo vách đá, chui qua rừng tre. "
				+ "Và đôi khi có thứ đuổi theo mình.",
		},
		{
			"type": "dialogue",
			"speaker": "Cô Lộng Gió",
			"title": "Nhẹ và bền",
			"body": "Mình cần thứ nhẹ đủ để không làm mình chậm. Nhưng đủ bền để mình tin khi cần. "
				+ "Không phải vũ khí của người muốn chiến thắng. Vũ khí của người muốn... "
				+ "vẫn còn ở đây ngày hôm sau.",
		},
		{
			"type": "dialogue",
			"speaker": "Người Giữ Lò",
			"title": "Đã hiểu",
			"body": "Tôi hiểu rồi.",
		},
	]


static func get_co_long_gio_second_dialogue() -> Array[Dictionary]:
	# Demo: lần gặp 2 xảy ra khi player quay lại Đồng Mây Trắng sau ngày đầu gặp nàng.
	# Nàng nhớ lời đề nghị cũ, hỏi thăm, và tease thêm về Di Vật Tổ Nghề.
	return [
		{
			"type": "dialogue",
			"speaker": "Cô Lộng Gió",
			"title": "Trở lại",
			"body": "Thợ rèn. Ngươi quay lại. Mình tưởng ngươi bận trả nợ.",
		},
		{
			"type": "dialogue",
			"speaker": "Người Giữ Lò",
			"title": "Vẫn còn đây",
			"body": "Vẫn đang làm. Cô đã nhận được thứ mình cần chưa?",
		},
		{
			"type": "dialogue",
			"speaker": "Cô Lộng Gió",
			"title": "Chưa",
			"body": "Chưa. Mình vẫn đang chờ. Nhưng... không phải vì ngươi chậm. "
				+ "Vì Di Vật không đơn giản như thế.",
		},
		{
			"type": "dialogue",
			"speaker": "Cô Lộng Gió",
			"title": "Di Vật Tổ Nghề",
			"body": "Mình đang giữ 18 thứ. Mỗi thứ mang tên một người thợ rèn "
				+ "đã biến mất theo cách khác nhau.\n"
				+ "Lò Thiêng là thứ cuối cùng họ để lại.",
		},
		{
			"type": "dialogue",
			"speaker": "Người Giữ Lò",
			"title": "Biến mất?",
			"body": "Họ đi đâu?",
		},
		{
			"type": "dialogue",
			"speaker": "Cô Lộng Gió",
			"title": "Chưa phải lúc",
			"body": "Mình chưa kể được. Ngươi chưa đủ lâu ở đây để nghe chuyện đó mà không bỏ đi.",
		},
		{
			"type": "dialogue",
			"speaker": "Cô Lộng Gió",
			"title": "Hứa hẹn",
			"body": "Rèn cho mình cái vũ khí đúng nhất đó. Khi ngươi đặt nó vào tay mình, "
				+ "mình sẽ kể từ đầu.",
		},
	]


static func get_day4_intro_steps() -> Array[Dictionary]:
	return [
		{
			"title": "Ngày 4 — Hạn Chót!",
			"body": "Hôm nay là ngày cuối trả nợ 3,000G.\n"
				+ "Bán hàng xong → nhấn 'Kết Thúc Ngày' → chọn 'Trả Nợ' "
				+ "ở màn tổng kết ban đêm.",
		},
	]
