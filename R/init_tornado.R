#' Initialize Settings for Adverse Event Tornado plot widget
#'
#' @param data named list of data
#' @param settings named list of settings
#'
#' @examples
#'
#' init_tornado(safetyData::aes, safetyGraphics::meta)
#' @return returns list with data and settings used for fct_tornadoplot
#'
#' @import dplyr
#' @import tidyr
#' @import ggplot2
#' @import stringr
#' @importFrom magrittr "%>%"
#' @export

init_tornado <- function(data, settings=NULL) {

  print(settings)
  print(head(data$aes))
  print(head(data$dm))
  # Merge treatment with adverse events.
  # Convert settings to symbols ready for standard evaluation
  dm_id_sym <- rlang::sym(settings$dm$id_col)
  dm_treatment_sym <- rlang::sym(settings$dm$treatment_col)
  print(dm_treatment_sym)

  ae_id_sym <- rlang::sym(settings$aes$id_col)
  ae_bodsys_sym <- rlang::sym(settings$aes$bodsys_col)
  ae_decod_sym <- rlang::sym(settings$aes$term_col)
  ae_severity_sym <- rlang::sym(settings$aes$severity_col)
  ae_serious_sym <- rlang::sym(settings$aes$serious_col)

  aes_arm <- data$aes %>%
    dplyr::left_join(
      data$dm %>% dplyr::select(!!dm_id_sym, !!dm_treatment_sym),
      by = settings$dm$id_col
    )

  # get treatments
  if(is.null(settings$dm[['treatment_values--group1']])){settings$dm[['treatment_values--group1']] <- "Placebo"}
  if(is.null(settings$dm[['treatment_values--group2']])){settings$dm[['treatment_values--group2']] <- "Treatment"}

  treatments <- c(
    settings$dm[['treatment_values--group1']],
    settings$dm[['treatment_values--group2']]
  )

  # TODO check that the treatments exists in the data

  if (length(treatments) < 2) {
    all_treatments <- unique(aes_arm %>% pull(!!dm_treatment_sym))
    treatments <- all_treatments[1:2]
  }

  data_dm <- data$dm %>%
    dplyr::group_by(!!dm_treatment_sym) %>%
    dplyr::mutate(bign = dplyr::n_distinct(!!dm_treatment_sym, !!dm_id_sym)) %>%
    dplyr::select(!!dm_id_sym, !!dm_treatment_sym, bign)

  data_ae <- data$aes %>%
    dplyr::inner_join(data_dm, by = settings$dm$id_col)  %>%
    dplyr::mutate(treatment_group = stringr::str_to_sentence(!!dm_treatment_sym),
                  bodsys_col = stringr::str_to_sentence(!!ae_bodsys_sym),
                  term_col = stringr::str_to_sentence(!!ae_decod_sym),
                  !!ae_severity_sym := factor(stringr::str_to_sentence(!!ae_severity_sym), levels = c("Severe", "Moderate", "Mild", "Total")),
                  !!ae_serious_sym := factor(stringr::str_to_sentence(!!ae_serious_sym), levels = c("Y", "N", "Total"),labels = c("Serious", "Not serious", "Total"))) %>%
    dplyr::ungroup() %>%
    dplyr::select(!!dm_id_sym, treatment_group, bign, bodsys_col, term_col, !!ae_severity_sym, !!ae_serious_sym)
  print(dim(data_ae))
  # frequency py PT and AE severity, as well as difference of frequency between both treatment arms
  data_ae1 <- data_ae %>%
    dplyr::mutate(None = factor("All")) %>%
    # Create Total severity rows
    dplyr::bind_rows(data_ae %>% mutate(None = "Total", !!ae_severity_sym := "Total", !!ae_serious_sym := "Total")) %>%
    tidyr::pivot_longer(cols = c(None, !!ae_severity_sym, !!ae_serious_sym), #pivot longer on flag data
                        names_to = "group_col",
                        values_to = "group_val") %>%
    dplyr::filter(!is.na(group_val)) %>%
    # Calculate frequencies usinf add_count function
    dplyr::add_count(bign, treatment_group, term_col, group_col, group_val, sort = TRUE) %>%
    dplyr::distinct(bign, treatment_group, term_col, group_col, group_val, n) %>%
    dplyr::arrange(bign, treatment_group, term_col, group_col, group_val, n) %>%
    # Create a variable 'tokeep' to keep only AEs with at least 3 occurences within both treatment arms
    dplyr::mutate(tokeep = if_else(group_val == "Total" & n > 5, 1, NA_real_)) %>%
    dplyr::group_by(term_col, group_col) %>%
    # Fill 'tokeep' created above within each AE decod
    tidyr::fill(tokeep, .direction = "downup") %>%
    dplyr::filter(tokeep == 1) %>%
    # Create percentage
    dplyr::mutate(perc_char = dplyr::if_else(n !=0, paste0(format(round(n/bign*100, 2), nsmall = 2), "%"),"0%"),
                  perc = dplyr::if_else(n !=0, round(n/bign*100, 2), 0),
                  treatment_group = dplyr::if_else(grepl("PLA", toupper(treatment_group)), "placebo", "treatment")) 
                  
    # if/then is a bit of a safetyGraphics hack ... can refactor later
    if(nrow(data_ae1)>0){
      # Pivot dataframe, to have a placebo and a treatment column
      data_ae2 <- data_ae1 %>% 
      tidyr::pivot_wider(
        id_cols = c(term_col, group_col, group_val),
        names_from = treatment_group,
        names_glue = "{treatment_group}_{.value}",
        values_from = perc,
        values_fill = 0
      ) %>%
      # Create difference of frequency
      dplyr::mutate(placebo_perc_minus = -placebo_perc,
                    total_perc = dplyr::if_else(group_val == "Total", placebo_perc + treatment_perc, NA_real_),
                    diff = treatment_perc - placebo_perc,
                    diff_pos = dplyr::if_else(diff > 0, diff, NA_real_),
                    diff_neg = dplyr::if_else(diff < 0, diff, NA_real_)) %>%
      tidyr::fill(total_perc, .direction = "downup")

    }else{
      data_ae2=data_ae1
    }

  #settings <- c(settings$aes, settings$dm)
  params <-
    list(
      data = data_ae2,
      settings = settings
    )

  return(params)
}
