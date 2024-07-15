Languages = {}

do
    Languages = {
        ['cn'] = {
            ['Error: CaptureZone - New(): trigger zone named [%s] not found.'] = 'Error: CaptureZone - New(): 没有找到名称为[%s]的触发区.',
        }
    }

    function Languages:translate(text, lang)
        if not text then 
            error("Languages:translate: text is nil.")
            return 
        end
        lang = lang or 'en'

        lang = lang:lower() -- 统一语言标识的大小写
        local translations = self[lang]
    
        if not translations then
            env.warning("Warning: Language '" .. lang .. "' not supported, falling back to English.")
            return text
        end
    
        local translatedText = translations[text]
        if not translatedText then
            env.warning("Warning: Translation for '" .. text .. "' not found in language '" .. lang .. "'.")
            return text
        end
    
        return translatedText
    end
end