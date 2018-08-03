import re
import json
from tkinter import Tk
from tkinter.filedialog import askopenfilename

#To Do: return types, support full API txt documentationument (including gfx variables)

json_data = {}
def CreateJSONEntry(base, body, documentation):
    retrieved_function = base.group(2) if base.group(1) == None else base.group(1)
    json_data[retrieved_function.upper() + " OSCIIBOT"] = {
        "prefix": base.group(1),
        "scope": "eel2",
        "body": body + "$0",
        "description": "[OSCIIBOT]\n\n" + documentation
    }
    
def main():

    Tk().withdraw()
    in_file = askopenfilename()

    if in_file == "":
        return

    with open(in_file) as input:

        base = ""
        body = ""
        documentation = ""
        empty_line_count = 0
        header_end = 3
        header_passed = False

        for i, line in enumerate(input):

            if empty_line_count == header_end:
                header_passed = True
                #gfx = False
                print("header passed")

            if line is "\n":
                empty_line_count += 1
                continue
            else:
                empty_line_count = 0

            """if re.search(r"Lua: gfx VARIABLES", line):
                header_passed = False
                gfx = True
                print("gfx enabled")
            
            if gfx:
                gfx_head = re.match(r"(.+)-", line)
                if gfx_head:
                    gfx_vars = re.findall(r"(gfx[.]\w+)", gfx_head.group(1))
                    gfx_desc = re.search(r"- (.*)", line)
                    for i, v in enumerate(gfx_vars):
                        CreateJSONEntry_GFX(v, v, gfx_desc)
            """

            if header_passed:
                #add check for gfx variables here
                check_function = re.search(r"^(\w+\((?:[\w\s_.,\"#&\[\]-]*|)\))|EEL: (gfx_\w+\((?:[\w\s_\".\[\],#&]*)\))", line)
                if check_function != None:
                    retrieved_function = check_function.group(2) if check_function.group(1) == None else check_function.group(1)
                    print(retrieved_function)

                    if documentation != "":
                        CreateJSONEntry(base, body, documentation)
                        documentation = ""

                    parameters = re.findall(r"\(*([-\w\s\"._]+)(?:[\[\]\),]{1,2})", retrieved_function)
                    base = re.match(r"(\w+)\(|gfx_(\w+)", retrieved_function)
                    #print(base.group(0) + "\n")

                    format_parameters = ""
                    delimiter = ", "
                    for i, p in enumerate(parameters):
                        if i == len(parameters) - 1:
                            delimiter = ""
                        if p.find("\""):
                            p = re.sub("\"", '', p)
                        format_parameters = format_parameters + "${" + str(i + 1) + ":" + p + "}" + delimiter

                    body = base.group(1) + "(" + format_parameters + ")"

                else:
                    documentation = documentation + line + "\n"

                CreateJSONEntry(base, body, documentation)

    with open("osciibot.code-snippets", 'w') as out_file:
        json.dump(json_data, out_file, indent=4)

main()