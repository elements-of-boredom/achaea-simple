local S = PkCore.sylvanPk

PkCore.pk.register("sylvan", {
  actions = S.actions,
  state = S,
  defaultRoute = "heartseed",
  routes = {
    heartseed = {
      "vinewreathe",
      "steal_body_restoration",
      "prep_torso",
      "wait_heartseed",
      "prep_bait",
      "heartseed_on_limb_salve",
      "heartseed_now",
      "break_bait",
      "wait_restoration",
    },
  },
})