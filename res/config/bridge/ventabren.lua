local path = "bridge/rail/ventabren/"
function data()
	return {
		name = _("Ventabren Viaduct"),

		yearFrom = 1990,
		yearTo = 0,

		carriers = { "RAIL" },

		pillarBase =   { path.."lgv_pillar_btm.mdl"},
		pillarRepeat = { path.."lgv_pillar_btm.mdl"},
		pillarTop =    { path.."lgv_pillar_top.mdl"},

		railingBegin =  { path.."lgv_railing_rep_side.mdl",   path.."lgv_railing_rep_rep.mdl" },
		railingRepeat = { path.."lgv_railing_rep_side.mdl",   path.."lgv_railing_rep_rep.mdl" },
		railingEnd =    { path.."lgv_railing_rep_side.mdl",   path.."lgv_railing_rep_rep.mdl" },

		cost = 540.0,
	}
end
