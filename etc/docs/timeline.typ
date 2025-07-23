#import "@preview/timeliney:0.3.0"

#let numtomonth(num) = {
  datetime(day: 1, month: num, year: 2000).display("[month repr:short]")
}

#timeliney.timeline(
  show-grid: true,
  {
    import timeliney: *

    headerline(group(([*2025*], 5)), group(([*2026*], 2)))
    headerline(
      group(..range(7, 12).map(n => strong(numtomonth(n + 1)))),
      group(..range(2).map(n => strong(numtomonth(n + 1)))),
    )

    taskgroup(title: [*Correctness*], {
      task("vim motions", (0, 1.4), style: (stroke: 2pt + gray))
      task("THING", (1, 3), style: (stroke: 2pt + gray))
    })

    taskgroup(title: [*Features*], {
      task("THING", (2, 3), style: (stroke: 2pt + gray))
      task("THING", (3, 5), style: (stroke: 2pt + gray))
    })

    taskgroup(title: [*Speed*], {
      task("Benchmarking", (3.5, 5), style: (stroke: 2pt + gray))
      task("THING", (4, 5.5), style: (stroke: 2pt + gray))
    })

    milestone(
      at: 0.1,
      style: (stroke: (paint: red, dash: "dashed")),
      align(center, [
        *Present*\
        Jul 23 2025
      ])
    )

    milestone(
      at: 0.5,
      style: (stroke: (dash: "dashed")),
      align(center, [
        *v0.1.1*\
        Aug 14 2025
      ])
    )

    milestone(
      at: 2.2,
      style: (stroke: (dash: "dashed")),
      align(center, [
        *v0.2.0*\
        Oct 2025
      ])
    )

    milestone(
      at: 6.5,
      style: (stroke: (dash: "dashed")),
      align(center, [
        *v0.3.0*\
        Feb 2026
      ])
    )
  }
)

