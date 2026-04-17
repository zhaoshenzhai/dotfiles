$always_view_file_via_temporary = 0;
$success_cmd = q(
    zathura %R.pdf &&
    pdflatex -synctex=1 -interaction=nonstopmode -jobname=%R_Student %S &&
    biber %R_Solutions &&
    pdflatex -synctex=1 -interaction=nonstopmode -jobname=%R_Student %S
);
