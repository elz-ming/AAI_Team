// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = [
  #line(start: (25%,0%), end: (75%,0%))
]

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): set block(
    fill: luma(230),
    width: 100%,
    inset: 8pt,
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.amount
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == "string" {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == "content" {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subrefnumbering: "1a",
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => numbering(subrefnumbering, n-super, quartosubfloatcounter.get().first() + 1))
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => {
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          }

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != "string" {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    block(below: 0pt, new_title_block) +
    old_callout.body.children.at(1))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: white, width: 100%, inset: 8pt, body))
      }
    )
}


#let poster(
  // The poster's size.
  size: "'36x24' or '48x36''",

  // The poster's title.
  title: "Paper Title",

  // A string of author names.
  authors: "Author Names (separated by commas)",

  // Department name.
  departments: "Department Name",

  // University logo.
  univ_logo: "Logo Path",

  // Footer text.
  // For instance, Name of Conference, Date, Location.
  // or Course Name, Date, Instructor.
  footer_text: "Footer Text",

  // Any URL, like a link to the conference website.
  footer_url: "Footer URL",

  // Email IDs of the authors.
  footer_email_ids: "Email IDs (separated by commas)",

  // Color of the footer.
  footer_color: "Hex Color Code",

  // DEFAULTS
  // ========
  // For 3-column posters, these are generally good defaults.
  // Tested on 36in x 24in, 48in x 36in, and 36in x 48in posters.
  // For 2-column posters, you may need to tweak these values.
  // See ./examples/example_2_column_18_24.typ for an example.

  // Any keywords or index terms that you want to highlight at the beginning.
  keywords: (),

  // Number of columns in the poster.
  num_columns: "3",

  // University logo's scale (in %).
  univ_logo_scale: "100",

  // University logo's column size (in in).
  univ_logo_column_size: "10",

  // Title and authors' column size (in in).
  title_column_size: "20",

  // Poster title's font size (in pt).
  title_font_size: "48",

  // Authors' font size (in pt).
  authors_font_size: "36",

  // Footer's URL and email font size (in pt).
  footer_url_font_size: "30",

  // Footer's text font size (in pt).
  footer_text_font_size: "40",

  // The poster's content.
  body
) = {
  // Set the body font.
  set text(font: "STIX Two Text", size: 16pt)
  let sizes = size.split("x")
  let width = int(sizes.at(0)) * 1in
  let height = int(sizes.at(1)) * 1in
  univ_logo_scale = int(univ_logo_scale) * 1%
  title_font_size = int(title_font_size) * 1pt
  authors_font_size = int(authors_font_size) * 1pt
  num_columns = int(num_columns)
  univ_logo_column_size = int(univ_logo_column_size) * 1in
  title_column_size = int(title_column_size) * 1in
  footer_url_font_size = int(footer_url_font_size) * 1pt
  footer_text_font_size = int(footer_text_font_size) * 1pt

  // Configure the page.
  // This poster defaults to 36in x 24in.
  set page(
    width: width,
    height: height,
    margin: 
      (top: 1in, left: 2in, right: 2in, bottom: 2in),
    footer: [
      #set align(center)
      #set text(32pt)
      #block(
        fill: rgb(footer_color),
        width: 100%,
        inset: 20pt,
        radius: 10pt,
        [
          #text(font: "Courier", size: footer_url_font_size, footer_url) 
          #h(1fr) 
          #text(size: footer_text_font_size, smallcaps(footer_text)) 
          #h(1fr) 
          #text(font: "Courier", size: footer_url_font_size, footer_email_ids)
        ]
      )
    ]
  )

  // Configure equation numbering and spacing.
  set math.equation(numbering: "(1)")
  show math.equation: set block(spacing: 0.65em)

  // Configure lists.
  set enum(indent: 10pt, body-indent: 9pt)
  set list(indent: 10pt, body-indent: 9pt)

  // Configure headings.
  set heading(numbering: "I.A.1.")
  show heading: it => locate(loc => {
    // Find out the final number of the heading counter.
    let levels = counter(heading).at(loc)
    let deepest = if levels != () {
      levels.last()
    } else {
      1
    }

    set text(24pt, weight: 400)
    if it.level == 1 [
      // First-level headings are centered smallcaps.
      #set align(center)
      #set text({ 32pt })
      #show: smallcaps
      #v(50pt, weak: true)
      #if it.numbering != none {
        numbering("I.", deepest)
        h(7pt, weak: true)
      }
      #it.body
      #v(35.75pt, weak: true)
      #line(length: 100%)
    ] else if it.level == 2 [
      // Second-level headings are run-ins.
      #set text(style: "italic")
      #v(32pt, weak: true)
      #if it.numbering != none {
        numbering("i.", deepest)
        h(7pt, weak: true)
      }
      #it.body
      #v(10pt, weak: true)
    ] else [
      // Third level headings are run-ins too, but different.
      #if it.level == 3 {
        numbering("1)", deepest)
        [ ]
      }
      _#(it.body):_
    ]
  })

  // Arranging the logo, title, authors, and department in the header.
  align(center,
    grid(
      rows: 2,
      columns: (univ_logo_column_size, title_column_size),
      column-gutter: 0pt,
      row-gutter: 50pt,
      image(univ_logo, width: univ_logo_scale),
      text(title_font_size, title + "\n\n") + 
      text(authors_font_size, emph(authors) + 
          "   (" + departments + ") "),
    )
  )

  // Start three column mode and configure paragraph properties.
  show: columns.with(num_columns, gutter: 64pt)
  set par(justify: true, first-line-indent: 0em)
  show par: set block(spacing: 0.65em)

  // Display the keywords.
  if keywords != () [
      #set text(24pt, weight: 400)
      #show "Keywords": smallcaps
      *Keywords* --- #keywords.join(", ")
  ]

  // Display the poster's contents.
  body
}

// Typst custom formats typically consist of a 'typst-template.typ' (which is
// the source code for a typst template) and a 'typst-show.typ' which calls the
// template's function (forwarding Pandoc metadata values as required)
//
// This is an example 'typst-show.typ' file (based on the default template  
// that ships with Quarto). It calls the typst function named 'article' which 
// is defined in the 'typst-template.typ' file. 
//
// If you are creating or packaging a custom typst template you will likely
// want to replace this file and 'typst-template.typ' entirely. You can find
// documentation on creating typst templates here and some examples here:
//   - https://typst.app/docs/tutorial/making-a-template/
//   - https://github.com/typst/templates

#show: doc => poster(
   title: [Visualizing Trends in Public Transport Ridership in Singapore], 
  // TODO: use Quarto's normalized metadata.
   authors: [Tamo Cholo Rafael Tandoc, Chua Zong Han Lionel, Nurul Shaidah, Poh Wen Lin Rachel, Lin Zhenming], 
   departments: [Team 12], 
   size: "36x24", 

  // Institution logo.
   univ_logo: "./images/sit.png", 

  // Footer text.
  // For instance, Name of Conference, Date, Location.
  // or Course Name, Date, Instructor.
   footer_text: [AAI1001 — Data Engineering and Visualization AY24/25 Tri 2 Team Project], 

  // Any URL, like a link to the conference website.
   footer_url: [~], 

  // Emails of the authors.
   footer_email_ids: [Team 12], 

  // Color of the footer.
   footer_color: "ebcfb2", 

  // DEFAULTS
  // ========
  // For 3-column posters, these are generally good defaults.
  // Tested on 36in x 24in, 48in x 36in, and 36in x 48in posters.
  // For 2-column posters, you may need to tweak these values.
  // See ./examples/example_2_column_18_24.typ for an example.

  // Any keywords or index terms that you want to highlight at the beginning.
  

  // Number of columns in the poster.
  

  // University logo's scale (in %).
  

  // University logo's column size (in in).
  

  // Title and authors' column size (in in).
  

  // Poster title's font size (in pt).
  

  // Authors' font size (in pt).
  

  // Footer's URL and email font size (in pt).
  

  // Footer's text font size (in pt).
  

  doc,
)

= Introduction
<introduction>
Public transport is essential for urban mobility in Singapore, serving millions daily. Understanding ridership trends is crucial for urban planning and policy making. Current visualizations highlight broad trends but lack context, interactivity, and data granularity. This project aims to enhance an existing ridership visualization by incorporating better color differentiation, trend indicators, and interactive elements to provide deeper insights into usage patterns.

= Original Visualization
<original-visualization>
A stacked bar chart published by The Straits Times (2025) presents annual ridership trends for MRT, LRT, and buses. While effectively conveys general trends, it lacks annotations, detailed breakdowns, and interactive features, making it harder to analyze fluctuations in riderships.

#figure([
#box(image("./images/figure_1.png", width: 85%))
], caption: figure.caption(
position: bottom, 
[
#link("https://www.straitstimes.com/singapore/transport/mrt-lrt-ridership-surpasses-pre-covid-19-levels-for-first-time-in-2024")[Original Visualization from the Straits Times (2025) .]
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-1>


= Critical Assessment of the Original Visualization
<critical-assessment-of-the-original-visualization>
+ #strong[Lack of Contextual Annotation];-No annotations to explain major events affecting riderships, such as the COVID-19 pandemic. \
+ #strong[Minimal Color Differentiation] - MRT, LRT, and bus ridership segments are not distinct enough, making it difficult to differentiate between them. \
+ #strong[No percentage Change Indicators] - The chart displays raw numbers but lacks insights into year-over-year growth or decline. \
+ #strong[Limited Data Granularity] - Only annual data is presented, missing seasonal patterns or short-term ridership fluctuations. \
+ #strong[Axis in Time Series] - The original graph places years on the y-axis, which is unconventional for time series data. This reduces readability and makes it harder to identify patterns or trends over time

= Suggested Improvement
<suggested-improvement>
+ #strong[Add Contextual Annotations] - Highlight key events impact,(e.g., COVID-19 impact, fare adjustments) to explain ridership shifts.
+ #strong[Improve Color Differentiation] - Use distinct, high-contrast colors for each transport mode to enhance readability.
+ #strong[Include Percentage Change] - Show year-over-year ridership variations for clearer trend analysis.
+ #strong[Increase Data Granularity] - Incorporate monthly or quarterly breakdowns to reveal seasonal patterns.
+ #strong[Use Appropriate Time Axis] - Place time (years or months) on the x-axis instead of the y-axis to follow standard time series conventions. This improves readability and makes it easier to observe trends and temporal patterns.

= Implementation
<implementation>
- #strong[Data Sources:]
  - #emph[Monthly Data (2019–2024)];: Contains monthly ridership figures over five years.
  - #emph[Yearly Data (1990–2023)];: Includes annual ridership statistics spanning 33 years.
- #strong[Data Cleaning – Monthly Data:]
  - Split the combined `month` column (e.g., "Jan-19") into separate `Month` and `Year` columns for better temporal analysis.
- #strong[Data Cleaning – Yearly Data:]
  - Transposed the table for improved readability and analysis.
  - Converted from wide to long format.
  - Filtered records from 2018 onward to focus on more complete and relevant data.
  - Converted ridership data from thousands to actual values by multiplying relevant columns by 1,000.

= Improved Visualization
<improved-visualization>
#figure([
#box(image("./images/improved_visualisation.jpg", width: 85%))
], caption: figure.caption(
position: bottom, 
[
Improved Visualization
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)
<fig-2>


= Data Analysis
<data-analysis>
#strong[\1. Analysis of monthly ridership reveals strong alignment with major real-life events:]

#block[
#set enum(numbering: "a)", start: 1)
+ #strong[First significant dip] observed in April to June 2020, which aligns with Singapore’s Circuit Breaker period during the initial wave of COVID-19 restrictions.

+ #strong[Second dip] occurs between May to July 2021, corresponding with Singapore reverting to Phase 2 (Heightened Alert) due to the Delta variant outbreak.
]

These drops are not random but coincide with periods of restricted movement, remote working, and school closures. \
\
#strong[\2. Seasonal Effects and Monthly Trends]

June and December has the lowest ridership aligning with school holidays when fewer students commute. Ridership patterns align with Singapore’s school and work calendar, where demand drops during school holidays (June, December). \
\
#strong[\3. Year-over-Year Ridership Trends]

Comparing 2019 (pre-COVID) and 2023 (post-COVID), ridership in 2023 remains slightly lower despite improvements in transport infrastructure. \
\
This suggests lasting lifestyle shifts, such as hybrid work, remote learning, and flexible commuting patterns, have reduced the need for daily travel. Lifestyle changes brought by the pandemic continue to influence public transport usage, even as services recover and expand.

= Further Improvements
<further-improvements>
To further enhance the analysis of public transport trends, incorporating additional data dimensions would be highly beneficial. For example, breaking down MRT data by individual train lines could reveal more detailed usage trends and highlight lines with greater variability, potentially linked to local demographics, major employment areas, or residential zones. \
\
Additionally, integrating age-related data would provide valuable insights into how different age groups adjusted their travel behavior over time—such as whether younger populations returned to public transport more quickly than seniors post-disruption.

= Conclusion
<conclusion>
The sparkline can effectively communicate the trend of a bivariate time series data (ridership across multiple transport mode in our case). Users can compare the similarity (or differences) of trends across the multiple categories, as well as visualize common anomality that affects all categories.

= References
<references>
- The Straits Times. (2025). MRT, LRT ridership surpasses pre-COVID-19 levels for first time in 2024. The Straits Times. https:\/\/www.straitstimes.com/singapore/transport/mrt-lrt-ridership-surpasses-pre-covid-19-levels-for-first-time-in-2024

- McKinsey & Company. (2021). Building a transport system that works: Insights from 25 global cities. McKinsey & Company. https:\/\/www.mckinsey.com/\~/media/mckinsey/business%20functions/operations/our%20insights/building%20a%20transport%20system%20that%20works%20new%20charts%20five%20insights%20from%20our%2025%20city%20report%20new/elements-of-success-urban-transportation-systems-of-25-global-cities-july-2021.pdf

- The Straits Times. (2022). New Covid-19 rules kick in: Timeline of S’pore’s measures over the last 2 years. The Straits Times.https:\/\/www.straitstimes.com/singapore/two-years-of-twists-and-turns-a-timeline-of-singapores-covid-19-measures
