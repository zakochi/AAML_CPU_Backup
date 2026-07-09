# Software Templates

These files are starting points for local extensions.

```text
model_profile_template.cc  New `models/<name>_profile.cc` files
app_extension_template.cc  Extra app source files added with APP_EXTRA_SRCS
custom_instruction_template.cc  Raw CUSTOM-0 wrapper and cycle test skeleton
```

Use the templates as examples, then run:

```sh
make validate
make host-check APP_EXTRA_SRCS=templates/custom_instruction_template.cc
```

If the extension adds a new menu item, register the function in
`../project/user_menu.cc`.
