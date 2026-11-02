# @summary A cron schedule for the cron type: minute and hour are required; the other fields default to `*` and `root`.
type Portage::Cronschedule = Struct[{
  'minute'             => Pattern[/\A[0-9*,\/-]+\z/],
  'hour'               => Pattern[/\A[0-9*,\/-]+\z/],
  Optional['monthday'] => Pattern[/\A[0-9*,\/-]+\z/],
  Optional['month']    => Pattern[/\A[0-9A-Za-z*,\/-]+\z/],
  Optional['weekday']  => Pattern[/\A[0-9A-Za-z*,\/-]+\z/],
  Optional['user']     => Pattern[/\A[a-z_][a-z0-9_-]*\z/],
}]
