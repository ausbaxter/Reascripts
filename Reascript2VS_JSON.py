import re
import json
from tkinter import Tk
from tkinter.filedialog import askopenfilename

#To Do: return types, support full API txt documentationument (including gfx variables)

json_data = {}
def CreateJSONEntry(lang, gfx, base, body, documentation):
    #retrieved_function = base.group(2) if base.group(1) == None else base.group(1)
    if gfx:
        s = base + "$0"
    else:
        s = base + "(" + body + ")" + "$0"

    print(s + "\n")
    json_data[base.upper() + " " + lang] = {
        "prefix": base,
        "scope": lang.lower(),
        "body": s,
        "description": documentation
    }
def FormatParameters(match):
    format_parameters = ""
    delimiter = ", "
    option = False
    option_str = ""
    for i, p in enumerate(match):
        p = p.strip()
        if option:
            option_str = "["
            option = False
        if i == len(match) - 1:
            delimiter = ""
        # if p.find("[") != -1:
        #     p = re.sub("\[", '', p)
        #     option = True
        if p.find("\"") != -1:
            p = re.sub("\"", '', p)
            format_parameters = format_parameters + "\"" + "${" + option_str + str(i + 1) + ":" + p + "}" + "\"" + delimiter
        else:
            format_parameters = format_parameters + "${" + option_str + str(i + 1) + ":" + p + "}" + delimiter
    print(format_parameters + "\n")
    return format_parameters
    
def main():

    Tk().withdraw()
    in_file = askopenfilename()

    if in_file == "":
        return

    with open(in_file) as input:

        base = ""
        body = ""
        documentation = ""
        mouse_cap_doc = "is a bitfield of mouse and keyboard modifier state.\n\n1: left mouse button\n\n2: right mouse button\n\n4: Control key\n\n8: Shift key\n\n16: Alt key\n\n32: Windows key\n\n64: middle mouse button"
        empty_line_count = 0
        header_end = 3
        header_passed = False
        in_gfx = False
        empty_line_count = 0
        description_capture = False
        new_lua = False
        new_eel = False
        new_py = False
        gfx_string = ""

        for i, line in enumerate(input):

            if line.find("API Function List") != -1:
                header_passed = True
                print("header passed\n")

            if empty_line_count == 2 and in_gfx == False: #Function information complete add JSON Entry. Need to know when all languages have changed (use boolean toggle per language...)
                description_capture = False
                if new_lua:
                    CreateJSONEntry("lua", False, lua_func_name, formatted_lua_parameters, documentation)
                if new_eel:
                    CreateJSONEntry("eel2", False, eel_func_name, formatted_eel_parameters, documentation)
                if new_py:
                    CreateJSONEntry("python", False, py_func_name, formatted_py_parameters, documentation)
                print("Documentation: " + documentation)
                new_lua = False
                new_eel = False
                new_py = False
                documentation = ""
            elif in_gfx and empty_line_count == 3:
                in_gfx = False

            if header_passed:
                if in_gfx:
                    print("in gfx " + line + "\n")
                    query = re.match("(.*) - (.*)", line)
                    if query != None:
                        print("GROUP 1 QUERY GFX: " + query.group(1))
                        var = re.findall("([^,\s]+)", query.group(1))
                        if var[0] == "mouse_cap":
                            CreateJSONEntry(gfx_string, "False", var[0], var[0], mouse_cap_doc)
                        else:
                            for i, v in enumerate(var):
                                CreateJSONEntry(gfx_string, "False", v, v, query.group(2))
                else:
                    query = re.match("\A(EEL|Lua|Python): (.*)", line)
                    if query != None:
                        if query.group(1) == "EEL":
                            eel_definition = re.search("([\w_]+)\((.*)\)", query.group(2))
                            if query.string.find("EEL: gfx VARIABLES") != -1:
                                in_gfx = True
                                gfx_string = "eel2"
                            else:
                                new_eel = True
                                eel_func_name = eel_definition.group(1)
                                eel_parameters = re.findall("(\[.*\]|[^,[]+)", eel_definition.group(2))
                                print("EEL: " + eel_func_name + "\n")
                                formatted_eel_parameters = FormatParameters(eel_parameters)
                        elif query.group(1) == "Lua":
                            print(query.string)
                            if query.string.find("Lua: gfx VARIABLES") != -1:
                                in_gfx = True
                                gfx_string = "lua"
                            elif query.group(2).find("=") != -1:
                                new_lua = True
                                lua_definition = re.match("([\w\s,._]+) = ([\w.]+)\((.*)\)", query.group(2))
                                lua_returns = re.search("([^,]+)", lua_definition.group(1))
                                lua_func_name = lua_definition.group(2) #might need to reference this as a match type
                                lua_parameters = re.findall("(\[.*\]|[^,[]+)", lua_definition.group(3))
                                print("LUA: " + lua_func_name + "\n")
                                formatted_lua_parameters = FormatParameters(lua_parameters)
                            else:
                                new_lua = True
                                lua_definition = re.search("(reaper.\w+|gfx.\w+|\{reaper.\w+\}.\w+)\((.*)\)", query.group(2))
                                lua_func_name = lua_definition.group(1)
                                lua_parameters = re.findall("(\[.*\]|[^,[]+)", lua_definition.group(2))
                                print("LUA: " + lua_func_name + "\n")
                                formatted_lua_parameters = FormatParameters(lua_parameters)
                        elif query.group(1) == "Python":
                            new_py = True
                            py_definition = re.search("((?:RPR|BR|CF|FNG|NF|ReaPack|SNM|SN|ULT)[\w_]+)\((.*)\)", query.group(2))
                            py_func_name = py_definition.group(1)
                            py_parameters = re.findall("(\[.*\]|[^,[]+)", py_definition.group(2))
                            print("PYTHON: " + py_func_name + "\n")
                            formatted_py_parameters = FormatParameters(py_parameters)
                    elif query == None and empty_line_count == 1:
                        description_capture = True

                    if description_capture:
                        if line != "\n":
                            documentation = documentation + line + "\n"

                if line is "\n":
                    empty_line_count += 1
                    continue
                else:
                    empty_line_count = 0

            # if header_passed:
            #     #add check for gfx variables here
            #     check_function = re.search(r"(reaper.\w+\((?:[\w\s_.,]*|)\))|Lua: (gfx.\w+\((?:[\w\s_\".\[\],]*)\))", line)
            #     if check_function != None:
            #         retrieved_function = check_function.group(2) if check_function.group(1) == None else check_function.group(1)
            #         #print(retrieved_function)

            #         if documentation != "":
            #             CreateJSONEntry(base, body, documentation)
            #             documentation = ""

            #         parameters = re.findall(r"(\w[\w\s\"._]+)(?:[\[\]\),]{1,2})", retrieved_function)
            #         base = re.match(r"reaper.(\w+)|gfx.(\w+)", retrieved_function)
            #         #print(base.group(0) + "\n")

            #         format_parameters = ""
            #         delimiter = ", "
            #         for i, p in enumerate(parameters):
            #             if i == len(parameters) - 1:
            #                 delimiter = ""
            #             if p.find("\""):
            #                 p = re.sub("\"", '', p)
            #             format_parameters = format_parameters + "${" + str(i + 1) + ":" + p + "}" + delimiter

            #         body = base.group(0) + "(" + format_parameters + ")"

            #     else:
            #         documentation = documentation + line + "\n"

            #     CreateJSONEntry(base, body, documentation)
        
        #need to create one last entry...
        if new_lua:
            CreateJSONEntry("lua", "False", lua_func_name, formatted_lua_parameters, documentation)
        if new_lua:
            CreateJSONEntry("eel2", "False", eel_func_name, formatted_eel_parameters, documentation)
        if new_py:
            CreateJSONEntry("python", "False", py_func_name, formatted_py_parameters, documentation)

    with open("reaper-api.code-snippets", 'w') as out_file:
        json.dump(json_data, out_file, indent=4)

main()