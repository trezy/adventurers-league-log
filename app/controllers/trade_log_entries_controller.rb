# :nodoc:
class TradeLogEntriesController < LogEntriesController
  skip_before_action :authenticate_user!, only: [:show]

  add_crumb('Home', '/')
  before_filter :load_user
  before_filter :load_character
  before_filter :load_log_entry, only: [:show, :edit, :update, :destroy]
  before_filter :load_current_magic_items,
                only: [:new, :create, :edit, :update]
  before_filter :build_new_magic_item,
                only: [:new, :create, :edit, :update]
  before_filter :clean_up_params, only: [:create, :update]

  before_filter do
    add_crumb @character.name, user_character_path(@character.user, @character)
  end

  before_filter(only: [:new]) { add_crumb 'New Trade Log Entry' }
  before_filter(only: [:show, :edit]) { add_crumb 'Trade Log Entry' }

  def show
    authorize @log_entry
    @traded_magic_item = @log_entry.traded_magic_item
    @received_magic_items = @log_entry.magic_items.last
  end

  def new
    @log_entry = @character.trade_log_entries.new
    @log_entry.characters = [@character]
    authorize @log_entry
  end

  def create
    @log_entry = @character.trade_log_entries.build(log_entries_params)
    @log_entry.traded_magic_item = @new_magic_item
    @log_entry.characters = [@character]

    authorize @log_entry

    if @log_entry.save
      redirect_to user_character_path(current_user, @character, q: params[:q]),
                  flash: { notice: 'Successfully created trade log entry' }
    else
      flash.now[:error] = log_entry_error_message 'create'
      render :new, q: params[:q]
    end
  end

  def edit
    authorize @log_entry
  end

  def update
    authorize @log_entry
    if @log_entry.update_attributes(log_entries_params)
      redirect_to user_character_path(current_user, @character, q: params[:q]),
                  flash: { notice: 'Successfully updated trade log entry' }
    else
      flash.now[:error] = log_entry_error_message 'update'
      render :edit, q: params[:q]
    end
  end

  def destroy
    authorize @log_entry
    @log_entry.destroy

    redirect_to user_character_path(current_user, @character, q: params[:q]),
                flash: { notice: 'Successfully deleted trade log entry' }
  end

  protected

  def load_character
    @character   = Character.find(params[:character_id])
  end

  def load_log_entry
    @log_entry   = LogEntry.find(params[:id])
  end

  def load_current_magic_items
    log_ids = [nil]
    log_ids << @log_entry.id if @log_entry
    @magic_items = @character.magic_items
                             .where(trade_log_entry_id: log_ids)
  end

  def build_new_magic_item
    magic_item = MagicItem.find_by(id: new_magic_item_params)
    if magic_item.present?
      @new_magic_item = magic_item
    elsif @log_entry && @log_entry.magic_items.last
      @new_magic_item = @log_entry.magic_items.last
    else
      @new_magic_item = MagicItem.new(trade_log_entry_id: 0)
    end
  end

  def new_magic_item_params
    params[:trade_log_entry][:traded_magic_item] if params[:trade_log_entry]
  end

  def clean_up_params
    params[:trade_log_entry].delete(:traded_magic_item)
  end

  def log_entries_params
    params.require(:trade_log_entry)
          .permit(:date_played, :downtime_gained, :gp_gained, :traded_magic_item,
                  :notes, magic_items_attributes: magic_item_params)
  end
end
