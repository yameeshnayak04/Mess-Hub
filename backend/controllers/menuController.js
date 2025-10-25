const Menu = require('../models/Menu');
const Mess = require('../models/Mess');

// @desc    Set menu for a date
// @route   POST /api/menu
// @access  Private (Manager only)
exports.setMenu = async (req, res, next) => {
  try {
    const { date, lunchItems, dinnerItems } = req.body;

    // Find manager's mess
    const mess = await Mess.findOne({ owner: req.user.id });

    if (!mess) {
      return res.status(404).json({
        success: false,
        message: 'No mess found for this manager'
      });
    }

    // Normalize date to start of day
    const menuDate = new Date(date);
    menuDate.setHours(0, 0, 0, 0);

    // Check if menu already exists for this date
    let menu = await Menu.findOne({
      mess: mess._id,
      date: menuDate
    });

    if (menu) {
      // Update existing menu
      if (lunchItems) menu.lunchItems = lunchItems;
      if (dinnerItems) menu.dinnerItems = dinnerItems;
      await menu.save();
    } else {
      // Create new menu
      menu = await Menu.create({
        mess: mess._id,
        date: menuDate,
        lunchItems: lunchItems || [],
        dinnerItems: dinnerItems || []
      });
    }

    res.status(200).json({
      success: true,
      data: menu,
      message: menu.isNew ? 'Menu created successfully' : 'Menu updated successfully'
    });
  } catch (error) {
    next(error);
  }
};

// @desc    Get menu for a mess
// @route   GET /api/menu/:messId
// @access  Private
exports.getMenu = async (req, res, next) => {
  try {
    const { messId } = req.params;
    const { startDate, endDate } = req.query;

    // Build query
    const query = { mess: messId };

    if (startDate && endDate) {
      const start = new Date(startDate);
      start.setHours(0, 0, 0, 0);
      
      const end = new Date(endDate);
      end.setHours(23, 59, 59, 999);

      query.date = { $gte: start, $lte: end };
    } else if (startDate) {
      const start = new Date(startDate);
      start.setHours(0, 0, 0, 0);
      query.date = start;
    }

    const menus = await Menu.find(query).sort({ date: 1 });

    res.status(200).json({
      success: true,
      count: menus.length,
      data: menus
    });
  } catch (error) {
    next(error);
  }
};
