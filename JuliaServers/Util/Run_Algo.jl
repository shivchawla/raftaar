# © AIMSQUANT PVT. LTD.
# Author: Shiv Chawla
# Email: shiv.chawla@aimsquant.com
# Organization: AIMSQUANT PVT. LTD.

include("./daily.jl")
include("./minute.jl")

function _run_algo_internal(startdate::Date = getstartdate(), enddate::Date = getenddate(), resolution::Resolution = getresolution(); forward::Bool = false)
    if resolution == Resolution_Day
      _run_algo_day(startdate, enddate, forward)
    else
      _run_algo_minute(startdate, enddate, forward)
    end
end

function run_algo(forward_test::Bool = false)

  Logger.info_static("Running User algorithm")
  
  setcurrentdate(getstartdate())

  if forward_test
    # we're doing a forward test
    # Let's check if we have already saved data or not

    if !wasDataFound()
        # Oh no, no data found
        # let's call the initialize function
        
        println("Initializing")
        try
          API.setparent(:initialize)
          initialize(getstate())
          API.setparent(:all)
        catch err
          API.setparent(:all)
          handleexception(err, forward_test)
          _serializeData()
          return
        end
    end  
    
      # Aww yeah, data found
      # just set the start date from where you want to continue the forward testing
      # and let the fun begin

      _run_algo_internal(forward = forward_test)

      # Even if the simuation returned nothing (in case of missing security data)
      # we would like to reflect the end date for which the simuation ran
      # and then pass the previously serialized data itself
      # because this code region means, we already had some deserialized data to begin with
      
      _serializeData()

  else  ## Backtest
      # this means we are doing a backtest
      # nothing much to do here except for calling initialize

      try
        Logger.info_static("Initializing user algorithm")
        API.setparent(:initialize)
        initialize(getstate())
        API.setparent(:all)
      catch err
        API.setparent(:all)
        handleexception(err, forward_test)
        return
      end

      if(!_run_algo_internal())
        Logger.error_static("Missing Data or Internal Error")
        if !forward_test
            _outputbacktestlogs()
        end
      end
       
  end
end