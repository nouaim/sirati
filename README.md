<h1 align="center">
  <a href="https://github.com/nouaim/sirati" title="سيرتي">
    <img alt="سيرتي" src="icon.png" width="200px" height="200px" />
  </a>
  <br />
  سيرتي
</h1>

<p align="center">
  قالب سيرة ذاتية ورسالة تغطية بالعربية، من اليمين إلى اليسار، لـ LaTeX
</p>

<div align="center">
  <a href="https://github.com/posquit0/Awesome-CV">
    <img alt="Upstream" src="https://img.shields.io/badge/upstream-Awesome--CV-blue.svg" />
  </a>
  <a href="https://creativecommons.org/licenses/by-sa/4.0/">
    <img alt="License: CC BY-SA 4.0" src="https://img.shields.io/badge/license-CC%20BY--SA%204.0-blue.svg" />
  </a>
  <a href="https://github.com/nouaim/sirati/actions/workflows/main.yml">
    <img alt="Compile PDFs" src="https://github.com/nouaim/sirati/actions/workflows/main.yml/badge.svg" />
  </a>
  <a href="https://raw.githubusercontent.com/nouaim/sirati/main/examples/cv-ar.pdf">
    <img alt="Download the CV" src="https://img.shields.io/badge/CV-PDF-blue.svg" />
  </a>
  <a href="https://raw.githubusercontent.com/nouaim/sirati/main/examples/coverletter-ar.pdf">
    <img alt="Download the cover letter" src="https://img.shields.io/badge/Cover%20Letter-PDF-blue.svg" />
  </a>
</div>

<br />

<p align="center">
  <strong>العربية</strong> · <a href="README.en.md">English</a>
</p>


## ما هذا المشروع؟

**سيرتي** نسخة عربية من [Awesome CV](https://github.com/posquit0/Awesome-CV)،
القالب الذي أنشأه [Claud D. Park](https://github.com/posquit0) لـ LaTeX.

الأمثلة العربية هنا **مستندات XeLaTeX قائمة بذاتها**، مكتوبة لصفّ النص من اليمين إلى
اليسار عبر [polyglossia](https://ctan.org/pkg/polyglossia). لا يحتوي هذا المستودع على
ملف الصنف (class) الأصلي: فتخطيطه مبنيّ على جداول من اليسار إلى اليمين، أما التخطيط
العربي هنا فيأتي من إعداد اللغة نفسها. ولذلك تُصرَّف المستندات وحدها دون تثبيت أي صنف.

وإن أردت القالب الإنجليزي الأصلي وصنفه، فاستخدم
[مشروع Awesome CV الأصلي](https://github.com/posquit0/Awesome-CV)؛ فهو المرجع الأول،
وهذا المستودع مشتقّ منه.


## معاينة

* [السيرة الذاتية بالعربية (PDF)](examples/cv-ar.pdf)
* [رسالة التغطية بالعربية (PDF)](examples/coverletter-ar.pdf)

| السيرة الذاتية | رسالة التغطية |
|:---:|:---:|
| [![السيرة الذاتية](examples/cv-ar.png)](examples/cv-ar.pdf) | [![رسالة التغطية](examples/coverletter-ar.png)](examples/coverletter-ar.pdf) |

المستندان في صفحة واحدة. والصور أعلاه مولَّدة من ملفات PDF المبنيّة وتُحدَّث بالأمر
`make previews`.


## المتطلبات

هناك طريقتان للحصول على بيئة عمل كاملة: أن تثبّت المكوّنات على نظامك، أو أن تستخدم
صورة Docker التي يشحنها هذا المستودع. والاختبارات تغطّي الطريقتين، وطريق Docker يعمل
على أي نظام تشغيل.

ولا يُضمّن المستودع أي ملف خط، بل تُستدعى الخطوط بأسمائها العائلية، فعلى النظام أن
يوفّرها.

### ١. التثبيت على النظام (لينكس)

```bash
sudo apt install -y texlive-xetex texlive-latex-recommended texlive-latex-extra \
    texlive-fonts-recommended texlive-lang-arabic \
    fonts-roboto fontconfig poppler-utils make git python3 curl unzip
```

ولكل حزمة هنا سبب: `texlive-xetex` يوفّر محرّك **XeLaTeX**؛ و`texlive-lang-arabic`
يوفّر `bidi` التي تحتاجها **polyglossia** للنص من اليمين إلى اليسار؛
و`texlive-latex-extra` يوفّر `enumitem`؛ و`texlive-fonts-recommended` يوفّر مقاييس
الخط `pzdr` التي يحمّلها `hyperref` في XeLaTeX، وبدونه يتوقّف البناء عند
`Font \XeTeXLink@font=pzdr ... not loadable`؛ و`poppler-utils` يوفّر `pdftoppm`
و`pdfinfo` و`pdftotext` وهي لازمة للأمر `make previews` وللاختبارات؛ و`fontconfig`
يوفّر `fc-cache` و`fc-match`.

ويبقى أمران لا توفّرهما أي حزمة في التوزيعات، فأضفهما يدويًا.

**الخط العربي (Tajawal).**

```bash
mkdir -p ~/.local/share/fonts/tajawal && cd ~/.local/share/fonts/tajawal
for f in Regular Bold Medium; do
  curl -fsSLO "https://raw.githubusercontent.com/google/fonts/main/ofl/tajawal/Tajawal-$f.ttf"
done
fc-cache -f
fc-match Tajawal     # يجب أن يطبع Tajawal، فإن طبع خطًا آخر فلم يُسجَّل الخط
```

**خط الأيقونات (Font Awesome 7).** حزم Debian وUbuntu توفّر الإصدارين 4 و5 لا 7،
فخذه من CTAN إلى شجرة TeX الخاصة بك:

```bash
curl -fsSL -o /tmp/fontawesome7.zip https://mirrors.ctan.org/fonts/fontawesome7.zip
unzip -q -o /tmp/fontawesome7.zip -d /tmp/fontawesome7
cd /tmp/fontawesome7/fontawesome7
mkdir -p ~/texmf/tex/latex/fontawesome7
cp tex/* ~/texmf/tex/latex/fontawesome7/
for d in opentype type1 tfm enc map; do
  mkdir -p ~/texmf/fonts/$d/fontawesome7 && cp $d/* ~/texmf/fonts/$d/fontawesome7/
done
mktexlsr ~/texmf
kpsewhich fontawesome7.sty    # يجب أن يطبع المسار داخل ~/texmf
```

وإن كنت تفضّل أن يدير TeX Live حزمه بنفسه، فثبّت
[TeX Live من مصدره](https://tug.org/texlive/) ثم نفّذ `tlmgr install fontawesome7`
بدل كتلة CTAN أعلاه.

وأي خط عربي يصلح مكان Tajawal — **Amiri** (`fonts-hosny-amiri`) و
**Noto Naskh Arabic** (`fonts-noto-core`) كلاهما متوفّر كحزمة؛ غيّر اسم العائلة في
تمهيد المستندين.

### ٢. التثبيت عبر Docker (أي نظام تشغيل)

يحتوي المستودع على ملف `Dockerfile` مبنيّ على صورة `texlive/texlive` الرسمية مع إضافة
`poppler-utils` والخط العربي، فلا يُثبَّت شيء على نظامك. ابنِ الصورة مرة واحدة:

```bash
docker build -t sirati .
```

ثم نفّذ أي هدف من أهداف make داخلها مع وصل نسختك من المشروع:

```bash
docker run --rm --user "$(id -u):$(id -g)" -v "$PWD":/doc -w /doc sirati make
docker run --rm --user "$(id -u):$(id -g)" -v "$PWD":/doc -w /doc sirati make cv-ar
docker run --rm --user "$(id -u):$(id -g)" -v "$PWD":/doc -w /doc sirati make previews
docker run --rm --user "$(id -u):$(id -g)" -v "$PWD":/doc -w /doc sirati tests/check-arabic-examples.sh
```

وخيار `--user "$(id -u):$(id -g)"` مهم: فبدونه تصبح ملفات PDF مملوكة للمستخدم root.

أما وصفة المشروع الأصلي الأقصر — `docker run … texlive/texlive:latest make` — فلا
تكفي هنا: فتلك الصورة تحوي كل حزمة LaTeX تستخدمها هذه المستندات، لكنها لا تحوي Tajawal
ولا `poppler-utils`، فيفشل `make` على الخط العربي ولا يعمل `make previews` أصلًا.
والصورة كبيرة (قاعدة TeX Live فيها نحو ٩ غيغابايت) وتُسحب مرة واحدة.


## الاستخدام

ابنِ السيرة الذاتية العربية:

```bash
make cv-ar
```

وابنِ رسالة التغطية العربية:

```bash
make coverletter-ar
```

وفي الحالتين ينتج الملف `examples/cv-ar.pdf` أو `examples/coverletter-ar.pdf`.
ويمكنك التصريف مباشرة:

```bash
cd examples && xelatex cv-ar.tex
```

والأمر `make` وحده يبني المستندين.


## التخصيص

يضع المستندان بيانات الشخص في كتلة واحدة واضحة في أعلى الملف، وتُحفظ نصوص رسالة
التغطية في ملف منفصل (`examples/coverletter-ar/body.tex`) حتى يمكن تغيير الصياغة دون
المساس بالتخطيط:

* `examples/cv-ar.tex` — تخطيط السيرة الذاتية وبياناتها
* `examples/cv-ar/*.tex` — أقسام السيرة الذاتية
* `examples/coverletter-ar.tex` — تخطيط الرسالة وبياناتها
* `examples/coverletter-ar/body.tex` — نص الرسالة

والأمثلة تصف حاليًا **شخصًا وهميًا** يستخدم النطاق المحجوز `example.com`. استبدل تلك
القيم بقيمك.


### الورق

الورقة **بيضاء افتراضيًا**، ولا يلزم فعل شيء للبقاء عليها. وتأتي مع المستندين صبغة
اختيارية هي **ورق شامواه**، الورق الكريمي الذي تُطبع عليه الكتب العربية عادةً.

ولتشغيل الصبغة أزل التعليق عن سطرين في تمهيد كل مستند: سطر `\pagecolor`، وسطر خط
الأقسام الدافئ الذي يسبقه مباشرة:

```latex
\definecolor{sectiondivider}{HTML}{B9A87F}   % خط دافئ: الخط الرمادي يختفي على الصبغة
\pagecolor{shamwa}                           % الصبغة نفسها
```

والأمر `\pagecolor` من حزمة `xcolor` التي يستدعيها المستندان أصلًا، فلا حاجة إلى حزمة
إضافية؛ ويرسم XeLaTeX الصبغة عبر الخاصية `background` في مشغّل الرسوم xdvipdfmx.
وقيمة `shamwa` (`#F7F0DC`) معرَّفة بـ `\definecolor` فيمكن تعديل الدرجة كما تحب.
ولأن الصبغة تغطّي الورقة كاملةً من الحافة إلى الحافة، لا بد من ضبط الطابعة على طباعة
ألوان الخلفية لتظهر على الورق.


## شكر وتقدير

[**LaTeX**](https://www.latex-project.org) برنامج تنضيد رائع يستخدمه كثيرون، ولا سيما
في الرياضيات وعلوم الحاسوب في الأوساط الأكاديمية.

[**Awesome CV**](https://github.com/posquit0/Awesome-CV) المشروع الأصلي الذي اشتُقّ
منه هذا المستودع، أنشأه [Claud D. Park](https://github.com/posquit0) بمساهمات من
مجتمعه.

[**FontAwesome7 LaTeX Package**](https://ctan.org/pkg/fontawesome7) حزمة LaTeX توفّر
أيقونات [Font Awesome 7](https://fontawesome.com/v7/icons).

[**Tajawal**](https://github.com/googlefonts/tajawal) الخط العربي المستخدم في الأمثلة
العربية.

[**Roboto**](https://github.com/google/roboto) الخط الافتراضي في أندرويد وChromeOS،
والخط الموصى به للغة Google البصرية، Material Design.

[**Source Sans Pro**](https://github.com/adobe-fonts/source-sans-pro) مجموعة خطوط
OpenType مصمّمة للعمل جيدًا في واجهات المستخدم.


## الترخيص

كل ما في هذا المستودع — السيرة الذاتية العربية ورسالة التغطية وملفات أقسامهما وملفات
البناء — منشور تحت
[رخصة المشاع الإبداعي نَسب المُصنَّف — الترخيص بالمثل 4.0 دولي](https://creativecommons.org/licenses/by-sa/4.0/)
(CC BY-SA 4.0). ونصّ الرخصة الكامل في [LICENSE](LICENSE).

ولا يُوزَّع هنا أي ملف تحت رخصة LaTeX Project Public License، فملف `awesome-cv.cls`
من المشروع الأصلي **غير** مضمَّن عن قصد: فتخطيطه مبنيّ على جداول من اليسار إلى اليمين،
والمستندات العربية لا تستخدمه، وبإغفاله لا يبقى أي مكوّن تحت LPPL يلزم الالتزام به. وإن
أردته فخذه من [المشروع الأصلي](https://github.com/posquit0/Awesome-CV).


## ما تغيّر عن المشروع الأصلي

بالمقارنة مع [Awesome CV](https://github.com/posquit0/Awesome-CV)، هذا المستودع:

* يعيد كتابة السيرة الذاتية ورسالة التغطية كمستندين قائمين بذاتهما بـ XeLaTeX ومن
  اليمين إلى اليسار عبر [polyglossia](https://ctan.org/pkg/polyglossia)، بدل البناء
  على الصنف وتخطيطه من اليسار إلى اليمين؛
* يحذف ملف الصنف `awesome-cv.cls` كليًا؛
* يستبدل الأمثلة الإنجليزية بالزوج العربي، فيشحن المستودع سيرة ذاتية واحدة ورسالة
  تغطية واحدة بدل أمثلة متعددة؛
* يستخدم Font Awesome 7 بدلًا من Font Awesome 6؛
* يُبقي الورقة بيضاء لكنه يشحن صبغة ورق شامواه اختيارية، على بعد سطرين معلَّقين في كل
  مستند؛
* يجلب الخط العربي (Tajawal، برخصة SIL OFL 1.1) عند البناء بدل تضمين أي ملف خط.


## سياسة المشروع الأصلي

يطلب صاحب المشروع الأصلي عدم إعادة استخدام سيرته الذاتية، ونصّ طلبه:

> You are free to take my `.tex` file and modify it to create your own resume.
> Please don't use my resume for anything else without my permission, though!

ويحترم هذا المستودع ذلك الطلب؛ فمحتوى صاحب المشروع الأصلي الشخصي — اسمه وعنوانه
وبيانات اتصاله ومحتوى سيرته — ليس جزءًا من الأمثلة العربية، التي تصف شخصًا وهميًا
بدلًا منه.

وتبقى تعليقات النَسب التي تذكر المؤلف الأصلي في رؤوس ملفات المصدر عن قصد، لأن الرخصة
توجب حفظ الإشعارات.
