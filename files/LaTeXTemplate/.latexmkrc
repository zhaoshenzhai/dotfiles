$always_view_file_via_temporary = 0;
$success_cmd = q(
    pdflatex -interaction=nonstopmode -jobname=%R_Student %S &&
    biber %R_Solutions &&
    pdflatex -interaction=nonstopmode -jobname=%R_Student %S
);
