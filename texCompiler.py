import subprocess
import shutil
import os
import sys
import time

class LatexProjectCompiler:
    def __init__(
        self,
        project_name='document',
        main_tex_name=None,
        pdf_name=None,
        ignore_bibliography=False,
    ):
        self.workspace_dir = os.getcwd()
        self.project_dir = os.path.join(self.workspace_dir, project_name)
        self.output_dir = os.path.join(self.workspace_dir, 'output')
        self.logs_dir = os.path.join(self.workspace_dir, '__logs__')
        # Allow passing a main tex path relative to the project or an absolute path
        if os.path.isabs(main_tex_name):
            self.main_tex = main_tex_name
        else:
            self.main_tex = os.path.join(self.project_dir, main_tex_name)
        self.pdf_name = pdf_name
        self.pdf_path = os.path.join(self.project_dir, pdf_name)
        self.output_pdf_path = os.path.join(self.output_dir, pdf_name)
        self.aux_files = [f'{os.path.splitext(pdf_name)[0]}.{ext}' for ext in ['aux', 'log', 'out', 'toc']]
        self.ignore_bibliography = ignore_bibliography
        # # RNGNull setup
        # self.questions_src = os.path.join(self.project_dir, 'examples', 'questions.tex')
        # self.questions_temp = os.path.join(self.project_dir, 'examples', 'questions_temp.tex')
        # self.rngnull = RNGNull(self.questions_src, self.questions_temp)

    def ensure_directories(self):
        os.makedirs(self.output_dir, exist_ok=True)
        os.makedirs(self.logs_dir, exist_ok=True)

    def compile_latex(self):
        def run_cmd(cmd):
            subprocess.run(cmd, cwd=self.project_dir, check=True)

        def run_pdflatex():
            run_cmd([
                'pdflatex',
                '-shell-escape',
                '-interaction=nonstopmode',
                '-output-directory', self.project_dir,
                self.main_tex,
            ])

        def run_biber(base_name):
            run_cmd([
                'biber',
                '--input-directory', self.project_dir,
                '--output-directory', self.project_dir,
                base_name,
            ])

        error_occurred = False
        base_name = os.path.splitext(os.path.basename(self.main_tex))[0]

        try:
            bcf_path = os.path.join(self.project_dir, f"{base_name}.bcf")

            # Fast path: ignore bibliography => no biber, only 2 pdflatex passes.
            # (This matches the behavior/speed of oldmain.py.)
            if self.ignore_bibliography:
                print("Ignoring bibliography (-I bib): skipping biber.")
                run_pdflatex()
                run_pdflatex()
                return error_occurred

            # Normal path:
            # - Always run 2 pdflatex passes when there's no bibliography.
            # - If biblatex is used, run biber and then 2 more pdflatex passes.
            run_pdflatex()

            if os.path.exists(bcf_path):
                run_biber(base_name)
                run_pdflatex()
                run_pdflatex()
            else:
                # Some setups only emit the .bcf after the second pdflatex pass.
                run_pdflatex()
                if os.path.exists(bcf_path):
                    run_biber(base_name)
                    run_pdflatex()
                    run_pdflatex()
        except subprocess.CalledProcessError as e:
            print(f"LaTeX/Biber compilation error (exit code {e.returncode}). Attempting to move PDF if it exists...")
            error_occurred = True

        return error_occurred

    def move_pdf(self, error_occurred):
        if os.path.exists(self.pdf_path):
            shutil.move(self.pdf_path, self.output_pdf_path)
            print(f"PDF generated at: {self.output_pdf_path}")
            if error_occurred:
                print("Warning: LaTeX compilation returned an error, but PDF was generated and moved.")
        else:
            print("PDF not found. Compilation may have failed.")

    def move_aux_files(self):
        # Move standard aux files
        for fname in self.aux_files:
            src = os.path.join(self.project_dir, fname)
            dst = os.path.join(self.logs_dir, fname)
            if os.path.exists(src):
                shutil.move(src, dst)
                print(f"Moved {fname} to __logs__ directory.")
        # Also move project-related run files (e.g., main.bcf, main.run.xml)
        base_name = os.path.splitext(os.path.basename(self.main_tex))[0]
        extra_files = [
            f"{base_name}.bcf",
            f"{base_name}.bbl",
            f"{base_name}.blg",
            f"{base_name}.run.xml",
        ]
        for fname in extra_files:
            src = os.path.join(self.project_dir, fname)
            dst = os.path.join(self.logs_dir, fname)
            if os.path.exists(src):
                shutil.move(src, dst)
                print(f"Moved {fname} to __logs__ directory.")

    def run(self):
        self.ensure_directories()
        orig_questions = os.path.join(self.project_dir, 'examples', 'questions.tex')
        backup_questions = orig_questions + '.bak'
        backup_created = False
        if os.path.exists(orig_questions):
            shutil.copy2(orig_questions, backup_questions)
            backup_created = True
        try:
            error_occurred = self.compile_latex()
            self.move_pdf(error_occurred)
            self.move_aux_files()
        finally:
            if backup_created and os.path.exists(backup_questions):
                shutil.move(backup_questions, orig_questions)

class ArgC:
    def __init__(self, args):
        self.args = args

    def _flag_value(self, flag):
        if flag in self.args:
            idx = self.args.index(flag)
            if idx + 1 < len(self.args):
                return self.args[idx + 1]
        return None

    def _flag_values(self, flag):
        values = []
        i = 0
        while i < len(self.args):
            if self.args[i] == flag and i + 1 < len(self.args):
                values.append(self.args[i + 1])
                i += 2
                continue
            i += 1
        return values

    def _iter_positionals(self):
        # Yield args that are not flags and not values of flags-with-values.
        flags_with_values = {'-o', '-I', '-F'}
        skip_next = False
        for arg in self.args:
            if skip_next:
                skip_next = False
                continue
            if arg in flags_with_values:
                skip_next = True
                continue
            if arg.startswith('-'):
                continue
            yield arg

    def outputFlag(self):
        return '-o' in self.args

    def outputPath(self):
        return self._flag_value('-o')

    def ignoreTargets(self):
        return {v.lower() for v in self._flag_values('-I')}

    def ignoreBibliography(self):
        # Requested: -I bib
        targets = self.ignoreTargets()
        return 'bib' in targets or 'biber' in targets or 'bibliography' in targets

    def mainTex(self):
        for arg in self.args:
            if arg.endswith('.tex'):
                return arg
        return None

    def projectFolder(self):
        folder_from_flag = self._flag_value('-F')
        if folder_from_flag:
            return folder_from_flag

        for arg in self._iter_positionals():
            if not arg.endswith('.tex') and not arg.endswith('.pdf'):
                return arg
        return None

    def pdfName(self):
        for arg in self.args:
            if arg.endswith('.pdf'):
                return arg
        return None

if __name__ == "__main__":
    timestart = time.time()
    args = ArgC(sys.argv[1:])
    folder = args.projectFolder() or 'document'
    pdf_name = args.outputPath() or args.pdfName() or f'{folder}.pdf'
    ignore_bib = args.ignoreBibliography()

    main_tex = args.mainTex() or 'examGenerator.tex'
    compiler = LatexProjectCompiler(
        project_name=folder,
        main_tex_name=main_tex,
        pdf_name=pdf_name,
        ignore_bibliography=ignore_bib,
    )
    compiler.run()
    timeend = time.time()
    print(f"[SUCCESS] - Build made in: {timeend - timestart:.4f} seconds")