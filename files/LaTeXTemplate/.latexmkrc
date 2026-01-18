$always_view_file_via_temporary = 0;
$success_cmd = q(
    pdflatex -interaction=nonstopmode -jobname=%R_Solutions %S &&
    biber %R_Solutions &&
    pdflatex -interaction=nonstopmode -jobname=%R_Solutions %S
);
