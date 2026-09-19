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

يُفترض وجود توزيعة TeX كاملة تتضمّن **XeLaTeX** وحزمة **polyglossia**، ويُستحسن
[TeX Live](https://tug.org/texlive/).

وتحتاج الأمثلة العربية فوق ذلك إلى:

* **Font Awesome 7** — حزمة CTAN
  [`fontawesome7`](https://ctan.org/pkg/fontawesome7)، وهي توفّر أيقونات
  [Font Awesome 7](https://fontawesome.com/v7/icons)
* **خط عربي** — والأمثلة تستخدم **Tajawal** بالاسم العائلي
* **خط لاتيني** — والأمثلة تستخدم **Roboto** بالاسم العائلي

لا يُضمّن هذا المستودع أي ملف خط، بل تُستدعى الخطوط بأسمائها العائلية، وعلى نظامك أن
يوفّرها:

* **Roboto** متوفّر في معظم التوزيعات: `sudo apt install fonts-roboto`.
* **Tajawal** *غير* متوفّر في مستودعات التوزيعات المعتادة. نزّله من
  [Google Fonts](https://fonts.google.com/specimen/Tajawal)، وثبّت ملفات TTF في
  `~/.local/share/fonts` ثم شغّل `fc-cache -f`. أو غيّر اسم العائلة في تمهيد
  المستندين إلى خط عربي متوفّر لديك — **Amiri** (`fonts-hosny-amiri`) و
  **Noto Naskh Arabic** (`fonts-noto-core`) كلاهما متوفّر كحزمة.


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


## انظر أيضًا

* [Awesome Identity](https://github.com/posquit0/hugo-awesome-identity) — قالب Hugo لصفحة واحدة للتعريف بنفسك.
