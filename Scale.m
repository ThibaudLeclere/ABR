classdef Scale < double
    enumeration
        p(1e-12)
        n(1e-9)
        u(1e-6)
        m(1e-3)
        c(1e-2)
        d(1e-1)
        unit(1)
        da(1e1)
        h(1e2)
        k(1e3)
        M(1e6)
        G(1e9)
        T(1e12)
    end
    
    
    methods        
        
        
        function unitPrefix = get_UnitPrefix(scale)
            switch scale 
                case Scale.unit
                    unitPrefix = ''; 
                case Scale.u
                    unitPrefix = 'µ';                    
                otherwise 
                    unitPrefix = char(scale); 
            end
           
        end
    end
    methods (Static = true)
        function convertedData = convert_Units(data, dataUnit, targetUnit)
            
            alpha = dataUnit / targetUnit;
            
            convertedData = data .* alpha;
        end
    end
    
end