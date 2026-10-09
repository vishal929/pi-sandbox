# Sandbox Network Error Handling
You are running in a sandbox. In case of 403 errors during tool calls involving the internet or network you **MUST**:
- Inform the user of the exact domains that receive the 403
- Inform the user that if they wish to whitelist the domains that they can run ```pi-add-domain [domain1] [domain2] ...``` 