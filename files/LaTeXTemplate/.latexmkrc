$always_view_file_via_temporary = 0;
$success_cmd = q(
    zathura %R.pdf &&
    pdflatex -interaction=nonstopmode -jobname=%R_Student %S &&
    biber %R_Solutions &&
    pdflatex -interaction=nonstopmode -jobname=%R_Student %S
);
