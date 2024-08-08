Languages = {}

do
    Languages = {
        ['cn'] = {
            ['Error: CaptureZone - New(): trigger zone named [%s] not found.'] = 'Error: CaptureZone - New(): 没有找到名称为[%s]的触发区.',
            ['There is no available airbase for %s to spawn'] = '附近没有可以为 %s 出生的机场.',
        }
    }

    function Languages:translate(text, lang)
        if not text then 
            error("Languages:translate: text is nil.")
            return 
        end
        lang = lang or Config.lang or 'en'

        lang = lang:lower() -- 统一语言标识的大小写
        local translations = self[lang]
    
        if not translations then
            if lang ~= 'en' then
                env.warning("Warning: Language '" .. lang .. "' not supported, falling back to English.")
            end
            
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